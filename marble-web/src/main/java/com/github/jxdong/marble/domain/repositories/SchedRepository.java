package com.github.jxdong.marble.domain.repositories;


import com.github.jxdong.marble.domain.model.JobDetail;
import com.github.jxdong.marble.domain.model.Result;
import com.github.jxdong.marble.domain.model.SchedulerDetail;
import com.github.jxdong.marble.domain.model.ServerDetail;
import com.github.jxdong.marble.agent.entity.ClassInfo;

import java.util.List;
import java.util.Set;

/**
 * @author <a href="djx_19881022@163.com">jeff</a>
 * @version 2015/1/13 14:04
 */
public interface SchedRepository extends Repository{

    List<SchedulerDetail> querySchedByAppCode(String appCode);

    List<ServerDetail> querySchedServer( String appCode, String schedName);

    List<JobDetail> queryJob(String appCode, String schedName, String jobName);

    Result startJob(String appCode, String schedName, String jobName);

    Result pauseJob(String appCode, String schedName, String jobName);

    Result deleteJob(String appCode, String schedName, String jobName);

    Result updateJob(JobDetail jobDetail);

    Result addAppScheduler(SchedulerDetail schedulerDetail);

    Result addJob(JobDetail jobDetail);

    Result deleteScheduler(String appCode, String schedName);

    Result executeJobManually(String type, String serverIp, int serverPort, Set<ClassInfo> classInfoSet);

    Result stopJobImmediately(String operator, String appCode, String schedName, String jobName, List<String> serverIps);


}
