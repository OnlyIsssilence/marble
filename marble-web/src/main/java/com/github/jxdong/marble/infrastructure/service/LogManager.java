package com.github.jxdong.marble.infrastructure.service;

import com.github.jxdong.marble.common.util.DateUtil;
import com.github.jxdong.marble.common.util.StringUtils;
import com.github.jxdong.marble.domain.model.JobExecutionLog;
import com.github.jxdong.marble.domain.model.Page;
import com.github.jxdong.marble.domain.model.Result;
import com.github.jxdong.marble.infrastructure.repositories.mapper.mysql.JobExecutionLogMapper;
import com.github.pagehelper.PageHelper;
import com.google.common.collect.Lists;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.interceptor.TransactionAspectSupport;

import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 日志服务类
 * @author <a href="djx_19881022@163.com">jeff</a>
 * @version 2015/11/17 14:14
 */
@Component
public class LogManager {
    private static Logger logger = LoggerFactory.getLogger(LogManager.class);

    @Autowired
    private JobExecutionLogMapper jobLogMapper;

    public JobExecutionLog queryJobExecutionLogById(long id){
        if(id <= 0 ){
            logger.error("invalid id-{}", id);
            return null;
        }
        JobExecutionLog jobLog = null;
        try{
            jobLog = jobLogMapper.selectById(id);
        }catch (Exception e){
            logger.error("Query Job-Execution-Log exception. id:{} , detail: ", id, e);
        }
        return jobLog;
    }

    public JobExecutionLog queryJobExecutionLogByReqNo(String reqNo){
        if(StringUtils.isBlank(reqNo)){
            logger.error("invalid reqno-{}", reqNo);
            return null;
        }
        JobExecutionLog jobLog = null;
        try{
            jobLog = jobLogMapper.selectByRequestNo(reqNo);
        }catch (Exception e){
            logger.error("Query Job-Execution-Log exception. reqNo:{} , detail: ", reqNo, e);
        }
        return jobLog;
    }


    public List<JobExecutionLog> queryJobExecutionLog(String appCode,
                                                      String schedName,
                                                      String jobName,
                                                      String serverInfo,
                                                      String beginDate,
                                                      String endDate,
                                                      int reqResultCode,
                                                      int execResultCode,
                                                      String orderColumn, String orderDir, Page page){
        List<JobExecutionLog> jobLogs = null;
        try{
            Map<String, Object> param = new HashMap<>();
            param.put("appCode", appCode);
            param.put("schedName", schedName);
            param.put("jobName", jobName);
            if(StringUtils.isNotBlank(serverInfo)){
                param.put("serverInfo", serverInfo);
            }

            Date beginDateV = DateUtil.convertStr2Date(beginDate,DateUtil.YYYYMMDD);
            if(beginDateV != null){
                param.put("beginDate", DateUtil.formateDate(beginDateV,DateUtil.YYYYMMDD));
            }
            Date endDateV = DateUtil.convertStr2Date(endDate,DateUtil.YYYYMMDD);
            if(endDateV != null){
                param.put("endDate", DateUtil.formateDate(DateUtil.addDays(endDateV, 1),DateUtil.YYYYMMDD));
            }
            if(reqResultCode>0){
                param.put("reqResultCode", reqResultCode);
            }
            if(execResultCode>0){
                param.put("execResultCode", execResultCode);
            }
            if(StringUtils.isNotBlank(orderColumn)){
                param.put("orderColumn",orderColumn);
            }
            if(StringUtils.isNotBlank(orderDir)){
                param.put("orderDir",orderDir);
            }
            if(page != null){
                PageHelper.startPage(page.getCurrentPage(), page.getPageSize());
            }
            jobLogs = jobLogMapper.selectByMultiConditions(param);
            if(page != null){
                page.setTotalRecord(jobLogs);
            }
        }catch (Exception e){
            logger.error("Query Job-Execution-Log exception. detail: ", e);
        }
        return jobLogs;
    }


    public Result addJobExecutionLog(JobExecutionLog jobExecutionLog){
        if(jobExecutionLog == null){
            return Result.FAILURE("Job-Execution-Log cannot be empty");
        }
        try{
            jobExecutionLog.setId(0);
            jobLogMapper.insert(jobExecutionLog);
            return Result.SUCCESS();
        }catch (Exception e){
            logger.error("insert Job-Execution-Log exception. jobExecutionLog:{} , detail: ", jobExecutionLog, e);
        }
        return Result.FAILURE("Insert record failed.");
    }

    /**
     * Job执行日志删除
     * @param appCode 应用code
     * @param schedName 计划任务name
     * @param jobName job name
     * @return Result
     */
    public Result deleteJobExecutionLog(String appCode, String schedName, String jobName, boolean delProcessing){
        try{
            int rows = jobLogMapper.deleteJobLog(appCode, schedName, jobName, delProcessing?null:Lists.newArrayList(0,20));
            logger.info("Deleted job logs end. Criteria:AppCode-{}, SchedulerName-{}, jobName-{}. Affected ({}) rows", appCode, schedName, jobName, rows);
            return Result.SUCCESS();
        }catch (Exception e){
            logger.error("delete Job-Execution-Log({}) exception. detail: ", jobName, e);
            return Result.FAILURE("删除Job日志失败：" + e.getMessage());
        }
    }

    public Result deleteJobExecutionLog(long id){
        if(id <= 0 ){
            return Result.FAILURE("illegal id value");
        }
        try{
            jobLogMapper.deleteById(id);
            return Result.SUCCESS();
        }catch (Exception e){
            logger.error("delete Job-Execution-Log({}) exception. detail: ", id, e);
        }
        return Result.FAILURE("Delete record failed.");
    }

    @Transactional
    public Result clearQuartzDBData(){
        try {
            jobLogMapper.deleteQuartzJobDetail();
            jobLogMapper.deleteQuartzCronTriggers();
            jobLogMapper.deleteQuartzFiredTriggers();
            jobLogMapper.deleteQuartzLocks();
            jobLogMapper.deleteQuartzPausedTriggerGroups();
            jobLogMapper.deleteQuartzSchedState();
            jobLogMapper.deleteQuartzTriggers();
            return Result.SUCCESS();
        }catch (Exception e){
            logger.error("异常：", e);
            TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
            return Result.FAILURE("删除Quartz数据失败：" + e.getMessage());
        }
    }

    /**
     * 更新执行状态
     * @param requestNo 请求流水号
     * @param execCode 执行结果code
     * @param execMsg 执行结果描述
     * @param endTime 执行结束时间
     * @return Result
     */
    public Result updateExecuteResult(String requestNo, Integer reqResultCode, String reqResultMsg, Integer execCode, String execMsg, Date endTime) {
        if(StringUtils.isBlank(requestNo)){
            return Result.FAILURE("更新DB的执行状态失败：RequestNo不能为空");
        }
        try{
            JobExecutionLog log = jobLogMapper.selectByRequestNo(requestNo);
            if(log == null){
                return Result.FAILURE("DB中找不到RequestNo=["+requestNo+"]的记录");
            }
            if(reqResultCode != null){
                log.setReqResultCode(reqResultCode);
                log.setReqResultMsg(StringUtils.safeString(reqResultMsg, 500));
            }
            if(execCode != null){
                log.setExecResultCode(execCode);
                log.setExecResultMsg(StringUtils.safeString(execMsg, 1000));
            }
            if(endTime != null){
                log.setEndTime(endTime);
            }
            int ret = jobLogMapper.updateLog(log);
            if(ret <=0){
                return Result.FAILURE("更新DB中RequestNo=["+requestNo+"]记录的执行状态失败：更新到0条记录");
            }
        }catch (Exception e){
            logger.error("update execute result exception, detail: ", e);
        }

        return Result.SUCCESS();
    }

}
