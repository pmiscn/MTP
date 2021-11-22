unit MTP.Mpkg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Generics.Collections, qjson,
  MFP.Types, MFP.Utils, MFP.Crud, MFP.index, MFP.index.hash, MFP.index.rbtree, MFP.Package;

type
  TBytess = TArray<TBytes>;

  TIndexType = record
    Name: String;
    IndexType: integer;
  end;

  TIndexTypes = TArray<TIndexType>;

  TMFPConfig = record
    FilePool: boolean;
    PoolType: integer; // 1 count 2 size 3 timeout 4
    Count: integer;
    Size: int64;
    TimeoutMinute: int64;
    IndexType: integer; // 1 rbtree 2 hash
    IndexTypes: TIndexTypes;
    public
      class function create(): TMFPConfig; static;
      function getIndexType(aPackName: String): integer;
  end;

  TMFInfo = record
    index: integer;
    Path: String;
    IndexSize: uint64;
    // FileStream: TBufferedFileStream;
    LastReadTime: TDatetime;
    MFIndex: TMFIndex;
  end;

  TMFInfos = TList<TMFInfo>;

  TMFInfos_ = class helper for TMFInfos
    public
      function deleteLast(aclass: TMFIndexClass): boolean;
      function GetIndexSize(): uint64;
      function deleteTimeOut(MaxMinute: uint64; aclass: TMFIndexClass): integer;
  end;

  TMFP = class
    private

    protected
      FMFPConfig   : TMFPConfig;
      FMFInfos     : TMFInfos;
      FMFIndexClass: TMFIndexClass;

    public
      constructor create;
      destructor Destroy;

      function GetMFIndex(aPath: String; var aIndex: TMFIndex): boolean;
      function GetCount(const aPath: String): uint64;

      function GetItem(const aPath: String; const aItem: uint64; var aResult: TBytes; var aExt: String;
        var aPos: uint64): integer; overload;
      function GetItemFileName(const aPath: String; const aItem: uint64): String; overload;
      function ItenCount(const aPath: String): int64;
      function Find(const aPath: String; const afileName: ansistring; var aResult: TBytes; var aExt: String;
        var aPos: uint64): integer; overload;
      function Find(const aPath: String; const afileName: ansistring; var aResult: TBytes; var aExt: String;
        var APriorValues: TBytess; var ANextValues: TBytess; var APriorFilenames, ANextFilenames: TArray<string>;
        aPriorCount: integer = 0; aNextCount: integer = 0): integer; overload;

      // function Find(const aPath: String; const afileName: ansistring; var aResult: TCharArray; var aExt: String): integer;  overload;

  end;

var
  pubMFP: TMFP;
function MFP(): TMFP;

implementation

uses mu.fileinfo, dateutils;

{ TMFP }
function MFP(): TMFP;
begin
  if not assigned(pubMFP) then
    pubMFP := TMFP.create;
  result   := pubMFP;
end;

function getUsableMem(): uint64;

var
  MemInfo: TMemoryStatus;
begin
  // 用sizeof(MemoryStatus)填充dwLength成员
  MemInfo.dwLength := sizeof(MemoryStatus);
  // 获取内存信息
  GlobalMemoryStatus(MemInfo);
  // 内存使用百分比
  // Edit1.Text := IntToStr(Memlnfo.dwMemoryLoad) + '%';
  // 总物理内存(字节)
  // Edit2.Text := IntToStr(MemInfo dwTotalPhys);
  // 未使用物理内存(字节)
  result := (MemInfo.dwAvailPhys);
  // 交换文件大小(字节)
  // Edit4.Text := IntToStr(Memlnfo.dwTotalPageFile);
  // 未使用交换文件大小(字节)
  // Edit5.Text := IntToStr(MemInfo dwAvailPageFile);
  // 虚拟内存空间大小(字节)
  // Edit6.Text := IntToStr(MemInfo.dwTotalVirtual);
  // 未使用虚拟内存大小(字节)
  // Edit7.Text := IntToStr(Memlnfo.dwAvailVirtual);
end;

constructor TMFP.create;
var
  fn: String;
  js: TQjson;
begin
  FMFPConfig := TMFPConfig.create;
  FMFInfos   := TMFInfos.create;
  fn         := getexepath + 'config\MFPConfig.json';
  if fileExists(fn) then
  begin
    js := TQjson.create;
    try
      js.LoadFromFile(fn);
      js.ToRecord<TMFPConfig>(FMFPConfig);

      if FMFPConfig.PoolType = 2 then
      begin
        if FMFPConfig.Size <= 0 then
          FMFPConfig.Size := getUsableMem;
      end;
    finally
      js.Free;
    end;
  end;
end;

destructor TMFP.Destroy;
begin
  FMFInfos.Free;
end;

function TMFP.Find(const aPath: String; const afileName: ansistring; var aResult: TBytes; var aExt: String;
  var APriorValues, ANextValues: TBytess; var APriorFilenames, ANextFilenames: TArray<string>;
  aPriorCount, aNextCount: integer): integer;
var
  aIndex    : TMFIndex;
  pa, na, fa: TMFPosFindedArray;
  i         : integer;
  l         : uint64;
begin
  result := 0;
  l      := 0;
  if self.GetMFIndex(aPath, aIndex) then
  begin
    case self.FMFPConfig.getIndexType(afileName) of
      1:
        begin
          FMFIndexClass := TMFIndexRBTree;
          l             := TMFIndexRBTree(aIndex).Find(afileName, fa, pa, na, aPriorCount, aNextCount);
        end;
      2:
        begin
          FMFIndexClass := TMFIndexHash;
          l             := (aIndex as TMFIndexHash).Find(afileName, fa, pa, na, aPriorCount, aNextCount);
        end;
    end;

    if l > 0 then
    begin
      aIndex.GetOne(fa[0].Pos, aResult, aExt);
      result := length(aResult);
    end;
    l := length(pa);
    if l > 0 then
    begin
      setlength(APriorValues, l);
      setlength(APriorFilenames, l);
      for i := Low(APriorValues) to High(APriorValues) do
      begin
        aIndex.GetOne(pa[i].Pos, APriorValues[i], aExt);
        APriorFilenames[i] := pa[i].filename;
      end;
    end;
    l := length(na);
    if l > 0 then
    begin
      setlength(ANextValues, l);
      setlength(ANextFilenames, l);
      for i := Low(ANextValues) to High(ANextValues) do
      begin
        aIndex.GetOne(na[i].Pos, ANextValues[i], aExt);
        ANextFilenames[i] := na[i].filename;
      end;
    end;

  end;

end;

function TMFP.Find(const aPath: String; const afileName: ansistring; var aResult: TBytes; var aExt: String;
  var aPos: uint64): integer;
var
  aIndex: TMFIndex;
  fa    : TMFPosFindedArray;
  l     : uint64;
begin
  result := 0;
  l      := 0;
  if self.GetMFIndex(aPath, aIndex) then
  begin

    case self.FMFPConfig.getIndexType(afileName) of
      1:
        begin
          FMFIndexClass := TMFIndexRBTree;
          l             := TMFIndexRBTree(aIndex).Find(afileName, fa);
        end;
      2:
        begin
          FMFIndexClass := TMFIndexHash;
          l             := (aIndex as TMFIndexHash).Find(afileName, fa);
        end;
    end;

    if l > 0 then
    begin
      aIndex.GetOne(fa[0].Pos, aResult, aExt);
      aPos   := fa[0].Pos;
      result := length(aResult);
    end;

  end;
end;

function TMFP.GetCount(const aPath: String): uint64;
var
  aIndex: TMFIndex;
  fa    : TMFPosFindedArray;
  l     : uint64;
begin
  result := 0;
  l      := 0;
  if self.GetMFIndex(aPath, aIndex) then
  begin

    result := (aIndex as FMFIndexClass).itemcount;

  end;

end;

function TMFP.GetItem(const aPath: String; const aItem: uint64; var aResult: TBytes; var aExt: String;
  var aPos: uint64): integer;
var
  aIndex: TMFIndex;
  fa    : TMFPosFinded;
  l     : uint64;
  fd    : TMFFileDesp;
begin
  if self.GetMFIndex(aPath, aIndex) then
  begin
    fa := aIndex.GetItemByIndex(aItem);
    fd := aIndex.GetFileDesp(fa.Pos);
    aIndex.GetOne(fa.Pos, aResult);
    aExt := fd.fileinfo.FileExt.asstring;
    // aIndex.get
  end;
end;

function TMFP.GetItemFileName(const aPath: String; const aItem: uint64): String;
var
  aIndex: TMFIndex;
  fa    : TMFPosFinded;
  l     : uint64;
  fd    : TMFFileDesp;
begin
  result := '';

  if self.GetMFIndex(aPath, aIndex) then
  begin
    fa := (aIndex as FMFIndexClass).GetItemByIndex(aItem);
    // fd     := aIndex.GetFileDesp(fa.Pos);
    result := fa.filename;

  end;

end;

function TMFP.GetMFIndex(aPath: String; var aIndex: TMFIndex): boolean;
var
  i  : integer;
  mfi: TMFInfo;
begin
  result := false;

  for i := 0 to FMFInfos.Count - 1 do
  begin
    if FMFInfos[i].Path = aPath then
    begin
      mfi              := FMFInfos[i];
      aIndex           := mfi.MFIndex;
      mfi.LastReadTime := now();
      FMFInfos[i]      := mfi;
      result           := true;
      exit;
    end;
  end;

  // 如果没有，就添加
  if not fileExists(aPath) then
    exit;
  case FMFPConfig.PoolType of
    1:
      begin
        if self.FMFInfos.Count >= FMFPConfig.Count then
        begin
          // 删除最大的；
          self.FMFInfos.deleteLast(FMFIndexClass);
        end;
      end;
    2:
      begin
        if FMFPConfig.Size > 0 then
        begin
          while FMFInfos.GetIndexSize > FMFPConfig.Size do
          begin
            self.FMFInfos.deleteLast(FMFIndexClass);
          end;
        end;
      end;
    3:
      begin
        if FMFPConfig.TimeoutMinute > 0 then
        begin
          FMFInfos.deleteTimeOut(FMFPConfig.TimeoutMinute, FMFIndexClass);
        end;
      end;
  end;

  case self.FMFPConfig.getIndexType(aPath) of
    1:
      begin
        FMFIndexClass := TMFIndexRBTree;
        mfi.MFIndex   := TMFIndexRBTree.create(aPath);
      end;
    2:
      begin
        FMFIndexClass := TMFIndexHash;
        mfi.MFIndex   := TMFIndexHash.create(aPath);
      end;
  end;

  mfi.index        := FMFInfos.Count;
  mfi.Path         := aPath;
  mfi.LastReadTime := now();
  mfi.IndexSize    := mfi.MFIndex.IndexFileSize;

  FMFInfos.Add(mfi);
  aIndex := mfi.MFIndex;
  result := true;

end;

function TMFP.ItenCount(const aPath: String): int64;
var
  aIndex: TMFIndex;
  fa    : TMFPosFinded;
  l     : uint64;
  fd    : TMFFileDesp;
begin
  result := 0;
  if self.GetMFIndex(aPath, aIndex) then
  begin
    result := aIndex.itemcount;
  end;
end;

{ TMFPConfig }

class function TMFPConfig.create(): TMFPConfig;
begin
  with result do
  begin
    FilePool := true;
    PoolType := 1;
    // 1 count 2 size 3 timeout 4
    Count         := 1;
    Size          := 0;
    TimeoutMinute := 0;
    IndexType     := 1; // 1 rbtree 2 hash
  end;

end;

function TMFPConfig.getIndexType(aPackName: String): integer;
begin
  aPackName := changefileext(extractfilename(aPackName), '');

  for var i := Low(self.IndexTypes) to High(self.IndexTypes) do
  begin
    if self.IndexTypes[i].Name = aPackName then
    begin
      exit(IndexTypes[i].IndexType);
    end;
  end;
  result := self.IndexType;
end;

{ TMFInfos_ }

function TMFInfos_.deleteLast(aclass: TMFIndexClass): boolean;
var
  i, mindex: integer;
  lt       : TDatetime;
begin
  result := false;
  lt     := 0;
  mindex := -1;
  for i  := 0 to self.Count - 1 do
  begin
    if self[i].LastReadTime > lt then
    begin
      lt     := self[i].LastReadTime;
      mindex := i;
    end;
  end;
  if mindex >= 0 then
  begin
    (self[mindex].MFIndex as aclass).Free;
    self.Delete(mindex);
    result := true;
  end;
end;

function TMFInfos_.deleteTimeOut(MaxMinute: uint64; aclass: TMFIndexClass): integer;
var
  i : integer;
  dt: TDatetime;
begin
  result := 0;
  dt     := now() - dateutils.OneMinute * MaxMinute;
  for i  := self.Count - 1 downto 0 do
  begin
    if self[i].LastReadTime < dt then
    begin
      (self[i].MFIndex as aclass).Free;
      self.Delete(i);
      inc(result);
    end;
  end;
end;

function TMFInfos_.GetIndexSize: uint64;
var
  i: integer;
begin
  result := 0;
  for i  := 0 to self.Count - 1 do
  begin
    inc(result, self[i].IndexSize);
  end;

end;

end.
