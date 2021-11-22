# MTP
Delphi html mvc

基于QDAC的一个模版解析程序。

需要应用qdac www.qdac.cc 
https://github.com/pmiscn/MuObjectPool
https://github.com/pmiscn/FilePackage



当时为了找一个类似php里面的模版解析，delphi下看了几个，感觉不是我想要的，就自己写了一个。
数据类型基本以json为主，集成了四则运算，支持if for each等常见的逻辑处理。
支持自定义节点扩展，用plugins扩展

数据源支持本地问题，数据库，httpget，插件，以及我的filePackage，目录等等，支持扩展，一般来说，只要能获得json字符串的都能当数据源。


下面是几个例子；
 
<pre>

<#data origin="mudb" type="json" path="">
    {
    //这个如果有，就用，没有，就从配置文件
    Type:"mssql", //默认
    Config:{
    Server:{
    },
    SQL:"select top 50 userid,username ,Department,office,addtime from [dbo].[T_Users] where userid like :UID for json auto",
    Type:"sqljson"   // sql proc  sqljson procjson
    },
    //提交的值，不能是数组和对象
    Values:{
    UID:"0%"
    // id:"$id",  //$是Url的 querystring 参数
    }
    }
</#data>
</pre>
<pre>
<table>
    <tr><th>id</th><th>userid</th><th>username</th><th>Department</th><th>office</th><th>addtime</th></tr>
    <#each range="" filter="@II%2==0" datapath="" loopvar="@II">
        <tr class="<#if @II%2==0>row1</#if><#else>row2</#else>">
        <td><#>(@II+1)</#></td>
        <td><#>@userid+"："+@username</#></td>
        <td><#>@username</#></td>
        <td><#>@Department</#></td>
        <td><#>@office</#></td>
        <td><#>FormatDatetime("yyyy年MM月dd日",@addtime)</#></td>
        </tr>
    </#each>

    <#each range="" filter="SubStr(@userid,1,1)=='6'" datapath="" loopvar="@II">
        <tr class=<#if @II%2==0>"row1"</#if><#else>"row2"</#else> >
        <td><#>(@II+1)</#></td>
        <td><#>@userid+"："+@username</#></td>
        <td><#>@username</#></td>
        <td><#>@Department</#></td>
        <td><#>@office</#></td>
        <td><#>FormatDatetime("yyyy年MM月dd日",@addtime)</#></td>
        </tr>
    </#each>
</table>
<#>@</#>

</pre>
<pre>
<#for range="0..4" datapath="Data" filter="@II%2==1" loopvar="@II">
    <#for range="0..2" datapath="" loopvar="@I" filter="@II==@I">
        <#> @I+1 </#><#>@[@I].Name</#>
    </#for>
</#for>
 </pre>
<ul><#each datapath="Data" range="0..1" loopvar="@I" filter="Sum(Number(@ID)+1)== 2"><li><#>@I+"："+@Name</#></li></#each></ul>
<ul><#each datapath="Data" range="" loopvar="@I" filter='( (@ID >= "1") || (@ID== "2") )'><li><#>@Name</#></li></#each></ul>
<ul><#each datapath="Data" range="0..2" loopvar="@I" filter="1=1"><li><#>@Name</#></li></#each></ul>
<ul><#each datapath="Data" range="0,1,2" loopvar="@I" filter='((@ID= "1") || ((@ID= "2") or (@ID == "3" )))'><li><#>@Name</#></li></#each></ul>
<#calendar year="2020" month="1" dateformat="yyyy-MM-dd" class="mm" monthclass="mn" emptydateclass="nn" dateclass="" datapath="Date" datefield="date">
    <a href="/<#>@date</#>/" title="<#>@date</#>"><#>FormatDatetime("yyyy年MM月dd日",@date)</#></a><br /><em><#>@Count</#></em>
</#calendar>

<div>
    <ul>
        <#each datapath="Data">
            <li>
                <#if @ID="1">
                    <dl>
                        <dt><#> @ID+":"+@Name</#>:</dt>
                        <#each datapath="Score">
                            <dd><# @ /></dd>
                        </#each>
                    </dl>
                </#if>
                <#elseif @ID="2">
                    <# value="@Name + @ID + ((2+3)/10)" />
                </#elseif>
                <#elseif @ID="3">
                    <# @ID />
                </#elseif>
                <#else>NONE</#else>
            </li>
        </#each>
    </ul>
    <ul><#each datapath="Data"><li><# @Name /></li> </#each></ul>
</div> 

<#include path="header.htm" parse=true />
<div class="bd">
</div>
<#include path="footer.htm" />
