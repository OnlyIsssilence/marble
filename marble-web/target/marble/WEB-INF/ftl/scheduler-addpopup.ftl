<style>
    .server-port-input {
        margin: 0px 10px 0px 10px;
        width: 59px;
        height: 25px;
        line-height: 25px;
    }
</style>
<script>

    init.push(function () {
        // Setup validation
        $("#jq-validation-scheduler-form").validate({
            ignore: '.ignore, .select2-input',
            focusInvalid: false,
            rules: {
                'jq-validation-schedname': {
                    required: true,
                    alphanumeric:true,
                    maxlength: 30
                },
                'jq-validation-scheddesc': {
                    maxlength: 100
                }
            }
        });

        //根据appcode得到所有服务器信息
        if ("${appCode}" != "") {
            $.ajax({
                "url": "${basePath}/app/server/query",
                "data": {"_method_":"get","appCode":${appCode}},
                "type":"POST",
                "async": false,
                "error": function () {
                },
                "success": function (response) {
                    if (response != null && '0000' == response.resultCode) {
                        if (response == null || response.result == null || response.result.length == 0) {
                            return;
                        }
                        var serverList = response.result;
                        var serverDiv = "";
                        for (var index in serverList) {
                            serverDiv = serverDiv +
                            '<div class="message">' +
                            '<div class="action-checkbox">' +
                            '<label class="px-single"><input type="checkbox" sergroup="' + serverList[index].group + '" sername="' + serverList[index].name + '" name="serverinfo-select" value="' + serverList[index].id + '" class="px"><span class="lbl"></span></label>' +
                            '</div>' +
                            '<input type="text" class="from server-port-input" name="server-port" placeholder="输入所用端口号">' +
                            '<span class="from">' + serverList[index].group + '</span>' +
                            '<span class="from">' + serverList[index].name + '</span>' +
                            '<span class="from">' + serverList[index].ip + '</span>' +
                            '<span class="from">' + serverList[index].description + '</span>' +
                            '</div>';
                        }
                        $("#ui-tabs-servers-input p").html(serverDiv);
                    }
                }
            });

            //填充自动获取页面Tab
            var data = {};data.appCode = ${appCode};
            $.ajax({
                "url":"${basePath}/app/query",
                "data":{"_method_":"get", "jsonParam":JSON.stringify(data)},
                "type":"POST",
                "error":function(){
                },
                "success":function(response){
                    if(response != null && '0000' == response.resultCode){
                        var res = response.result[0];
                        var msg = '';
                        if(res.soaServiceName==null||res.soaServiceName.length<=0 || res.soaServiceNameSpace==null||res.soaServiceNameSpace.lenght<=0){
                            msg = '<span style="color:red;">SOA的应用信息未配置，无法自动获取</span>';
                        }else{
                            msg =  '<div class="message">' +
                            '<input type="text" class="from server-port-input" name="server-port" placeholder="输入所用端口号">' +
                            '自动根据 <span class="label label-success">[ '+res.soaServiceName+' + '+res.soaServiceNameSpace+' ] </span>获取' +
                            '</div>';
                        }
                        $("#ui-tabs-servers-auto p").html(
                           msg
                        );

                    }else{
                        $.growl.error({title:"查询APP信息失败：", message: response.resultMessage});
                    }
                }
            });
        }
        //添加新服务器
        $("#sched-add-new-server").click(function () {
            bootbox.alert("<strong>Oh sorry!</strong> 开发中... 敬请期待！");
            return false;
        });
    });

    init.push(function () {
        //保存记录
        $("#addNewScheduler-btn").click(function () {
            var validateResult = $("#jq-validation-scheduler-form").valid();
            if (!validateResult) {
                return;
            }
            var reqObj = new Object();
            var isValid = true;

            //判断当前哪个TAB页活
            var curTabA = $("#ui-tabs-servers > li.active").children("a");
            //校验自动查找
            if(curTabA!=null && curTabA.attr("href") =='#ui-tabs-servers-auto'){
                var socketNumber = $("#ui-tabs-servers-auto").find("input.server-port-input").val();
                if(socketNumber == null ||socketNumber.length <=0){
                    alert("输入打开的端口号");
                    return false;
                }
                //reqObj["serverDetails[0].id"] = $(this).val();
                reqObj["serverDetails[0].port"] = socketNumber;
                reqObj["serverDetails[0].ip"] = "AUTO";
            }else{
                //校验服务器选择
                var serverArray = $('input:checkbox[name=serverinfo-select]:checked');
                if (serverArray.length == 0) {
                    alert("至少选择一项服务器信息");
                    return false;
                }
                serverArray.each(function (i) {
                    reqObj["serverDetails[" + i + "].id"] = $(this).val();
                    var serverPort = $(this).parent().parent().next().val();
                    if (serverPort == null || serverPort.length == 0) {
                        alert("为【" + $(this).attr("sergroup") + ":" + $(this).attr("sername") + "】输入端口号");
                        isValid = false;
                        return false;
                    } else {
                        reqObj["serverDetails[" + i + "].port"] = serverPort;
                    }
                });

                if (!isValid) {
                    return;
                }
            }

            var schedName = $("#schedname-div").val();
            var schedDesc = $("#scheddesc-div").val();
            reqObj["_method_"] = "patch";
            reqObj["appDetail.code"] =${appCode};
            reqObj.name = schedName;
            reqObj.description = schedDesc;
            $.ajax({
                "url": "${basePath}/app/scheduler/add",
                "data": reqObj,//{"_method_":"patch","appDetail.code":${appCode},"name":schedName, "description":schedDesc},
                "type": "POST",
                "error": function () {
                },
                "success": function (response) {
                    if (response == null || '0000' != response.resultCode) {
                        $.growl.error({title: "添加失败：", message: response.resultMessage});
                    } else {
                        $.growl.notice({title: "提示：", message: "操作成功！"});
                        $('#addNewSchedulerDialog').modal("hide");
                        location.reload();
                    }
                }
            });
        });
    });
</script>
<!-- 添加Scheduler -->
<div id="addNewSchedulerDialog" class="modal fade" tabindex="-1" role="dialog" style="display: none;"
     aria-hidden="true">
    <div class="modal-content">
        <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
            <h4 class="modal-title" id="myModalLabel">添加新Scheduler</h4>
        </div>
        <div class="modal-body">
            <form class="form-horizontal" id="jq-validation-scheduler-form" novalidate="novalidate">
                <div class="note note-info">
                    基本信息录入
                </div>
                <div class="panel-body">
                    <div class="form-group">
                        <label class="col-sm-2 control-label">应用Code</label>

                        <div class="col-sm-10">
                            <span class="form-control add-appcode"
                                  style="background: #eee;border: none;">${appCode}</span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="jq-validation-schedname" class="col-sm-2 control-label">Scheduler名称</label>

                        <div class="col-sm-10">
                            <input type="text" class="form-control" id="schedname-div" name="jq-validation-schedname"
                                   placeholder="Scheduler名称">
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="jq-validation-scheddesc" class="col-sm-2 control-label">Scheduler描述</label>

                        <div class="col-sm-10">
                            <textarea class="form-control" id="scheddesc-div" name="jq-validation-scheddesc"
                                      placeholder="描述下这是个什么鬼..."></textarea>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-sm-2 control-label">Scheduler状态</label>

                        <div class="col-sm-10">
                            <span type="text" class="form-control"
                                  style="background: #eee;border: none;">初始状态（不可用）</span>
                        </div>
                    </div>
                </div>

                <div class="note note-info">
                    服务器相关信息录入
                </div>
                <div id="app-server-div" class="panel widget-messages">
                    <div class="panel-heading">
                        <span class="panel-title"><i class="panel-title-icon fa fa-list"></i>选择至少一项服务器信息</span>
                    </div>
                    <div class="panel-body">
                        <ul id="ui-tabs-servers" class="nav nav-tabs">
                            <li class="active">
                                <a href="#ui-tabs-servers-auto" data-toggle="tab">服务器IP自动查找 <span class="label label-warning">推荐</span></a>
                            </li>
                            <li class="">
                                <a href="#ui-tabs-servers-input" data-toggle="tab">指定服务器IP</a>
                            </li>
                        </ul>
                        <div class="tab-content tab-content-bordered">
                            <div class="tab-pane fade  active in" id="ui-tabs-servers-auto">
                                <p></p>
                            </div>
                            <div class="tab-pane fade" id="ui-tabs-servers-input">
                                <p>
                                     <span style="color: #989494;font-size: 13px;">当前应用还未添加任何服务器，<a href="${basePath}/app"
                                                                                                    style="font-weight: bolder;font-size: 14px;text-decoration: underline;">点我</a>跳转到应用页面添加</span>
                                </p>
                                <div class="pull-right">
                                    <button class="btn" id="sched-add-new-server"><i class="fa fa-plus text-success"></i> 添加新服务器
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="panel-footer clearfix">
                    </div>
                </div>
            </form>
        </div>
        <!-- / .modal-body -->
        <div class="modal-footer">
            <button type="button" class="btn btn-default" data-dismiss="modal">取消</button>
            <button id="addNewScheduler-btn" type="button" class="btn btn-primary">保 存</button>
        </div>
    </div>
</div>


