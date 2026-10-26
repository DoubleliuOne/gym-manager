package com.gym.course.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gym.course.entity.CourseSchedule;
import com.gym.course.mapper.CourseScheduleMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class CourseScheduleService extends ServiceImpl<CourseScheduleMapper, CourseSchedule> {

    /**
     * 校验排课冲突：同教练同一时段不能重复排课，且 startTime 必须早于 endTime
     */
    public void validateSchedule(CourseSchedule schedule, Long excludeId) {
        // 1. 校验时间合理性
        if (schedule.getStartTime() != null && schedule.getEndTime() != null) {
            if (!schedule.getStartTime().isBefore(schedule.getEndTime())) {
                throw new IllegalArgumentException("开始时间必须早于结束时间");
            }
        }

        // 2. 校验教练时间冲突
        if (schedule.getCoachId() != null && schedule.getClassDate() != null
                && schedule.getStartTime() != null && schedule.getEndTime() != null) {
            List<CourseSchedule> existing = lambdaQuery()
                    .eq(CourseSchedule::getCoachId, schedule.getCoachId())
                    .eq(CourseSchedule::getClassDate, schedule.getClassDate())
                    .eq(CourseSchedule::getStatus, 0)
                    .ne(excludeId != null, CourseSchedule::getId, excludeId)
                    .list();

            for (CourseSchedule s : existing) {
                if (isTimeOverlap(
                        schedule.getStartTime(), schedule.getEndTime(),
                        s.getStartTime(), s.getEndTime())) {
                    throw new IllegalArgumentException(
                            "教练在该时段已有排课冲突: "
                            + s.getClassDate() + " "
                            + s.getStartTime() + "-" + s.getEndTime()
                    );
                }
            }
        }
    }

    private boolean isTimeOverlap(LocalTime s1, LocalTime e1, LocalTime s2, LocalTime e2) {
        return s1.isBefore(e2) && e1.isAfter(s2);
    }

    public List<CourseSchedule> getSchedulesByDate(LocalDate date) {
        return lambdaQuery()
                .eq(CourseSchedule::getClassDate, date)
                .eq(CourseSchedule::getStatus, 0)
                .orderByAsc(CourseSchedule::getStartTime)
                .list();
    }

    public List<CourseSchedule> getAvailableSchedules() {
        return lambdaQuery()
                .ge(CourseSchedule::getClassDate, LocalDate.now())
                .eq(CourseSchedule::getStatus, 0)
                .apply("booked_count < actual_capacity")
                .orderByAsc(CourseSchedule::getClassDate, CourseSchedule::getStartTime)
                .list();
    }
}
