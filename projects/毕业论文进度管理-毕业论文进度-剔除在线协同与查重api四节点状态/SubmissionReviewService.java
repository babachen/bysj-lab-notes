// SubmissionReviewService.java (示意草稿，读者根据持久层框架自行装配)
package com.example.thesis.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.example.thesis.mapper.MilestoneSubmissionMapper;
import com.example.thesis.mapper.ReviewLogMapper;

@Service
public class SubmissionReviewService {
    private final MilestoneSubmissionMapper submissionMapper;
    private final ReviewLogMapper reviewLogMapper;

    public SubmissionReviewService(MilestoneSubmissionMapper submissionMapper, ReviewLogMapper reviewLogMapper) {
        this.submissionMapper = submissionMapper;
        this.reviewLogMapper = reviewLogMapper;
    }

    @Transactional(rollbackFor = Exception.class)
    public boolean executeReview(Long submissionId, Long teacherId, String action, String comment, Integer score) {
        // 1. 悲观锁或版本校验：锁定待审核记录
        var submission = submissionMapper.selectByIdForUpdate(submissionId);
        if (submission == null || submission.getStatus() != 1) {
            throw new IllegalStateException("提交记录不存在或非待审状态，操作已作废");
        }

        // 2. 查重硬指标限制：终稿阶段若查重率超过20%，系统禁止执行通过操作
        if ("FINAL_PAPER".equals(submission.getPhaseCode()) && "PASS".equals(action)) {
            if (submission.getPlagiarismRate() != null && submission.getPlagiarismRate().doubleValue() > 20.0) {
                throw new IllegalArgumentException("查重率高于 20.00%，系统红线拦截，不可评定为通过");
            }
        }

        // 3. 更新主阶段状态 (2:驳回, 3:通过)
        int nextStatus = "PASS".equalsIgnoreCase(action) ? 3 : 2;
        int rows = submissionMapper.updateStatus(submissionId, nextStatus);
        if (rows == 0) {
            throw new RuntimeException("状态已被其他线程刷新，更新失败");
        }

        // 4. 写流水日志
        reviewLogMapper.insertLog(submissionId, teacherId, action, score, comment);
        return true;
    }
}
