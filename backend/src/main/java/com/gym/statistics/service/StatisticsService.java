package com.gym.statistics.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.gym.booking.entity.Booking;
import com.gym.booking.mapper.BookingMapper;
import com.gym.card.entity.RenewalRecord;
import com.gym.card.mapper.RenewalRecordMapper;
import com.gym.coach.entity.Coach;
import com.gym.coach.mapper.CoachMapper;
import com.gym.course.entity.Course;
import com.gym.course.entity.CourseSchedule;
import com.gym.course.mapper.CourseMapper;
import com.gym.course.mapper.CourseScheduleMapper;
import com.gym.member.mapper.MemberMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StatisticsService {

    private final MemberMapper memberMapper;
    private final CourseMapper courseMapper;
    private final CourseScheduleMapper scheduleMapper;
    private final BookingMapper bookingMapper;
    private final RenewalRecordMapper renewalRecordMapper;
    private final CoachMapper coachMapper;

    public Map<String, Object> dashboard() {
        LocalDate today = LocalDate.now();
        List<Long> todayScheduleIds = scheduleMapper.selectList(
                new LambdaQueryWrapper<CourseSchedule>()
                        .eq(CourseSchedule::getClassDate, today)
                        .select(CourseSchedule::getId))
                .stream().map(CourseSchedule::getId).collect(Collectors.toList());
        long todayBookings = 0;
        if (!todayScheduleIds.isEmpty()) {
            todayBookings = bookingMapper.selectCount(new LambdaQueryWrapper<Booking>()
                    .in(Booking::getScheduleId, todayScheduleIds)
                    .in(Booking::getStatus, 0, 1));
        }
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("totalMembers", memberMapper.selectCount(null));
        data.put("totalCourses", courseMapper.selectCount(null));
        data.put("totalCoaches", coachMapper.selectCount(null));
        data.put("todayBookings", todayBookings);
        return data;
    }

    public List<Map<String, Object>> courseBookingStats(LocalDate start, LocalDate end) {
        List<CourseSchedule> schedules = scheduleMapper.selectList(
                new LambdaQueryWrapper<CourseSchedule>()
                        .between(CourseSchedule::getClassDate, start, end)
                        .orderByAsc(CourseSchedule::getClassDate));
        Map<Long, Course> courseMap = courseMapper.selectList(null)
                .stream().collect(Collectors.toMap(Course::getId, c -> c));
        Map<Long, Coach> coachMap = coachMapper.selectList(null)
                .stream().collect(Collectors.toMap(Coach::getId, c -> c));
        List<Map<String, Object>> result = new ArrayList<>();
        for (CourseSchedule s : schedules) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("date", s.getClassDate());
            Course course = courseMap.get(s.getCourseId());
            row.put("courseName", course != null ? course.getName() : "未知");
            Coach coach = coachMap.get(s.getCoachId());
            row.put("coachName", coach != null ? coach.getName() : "未知");
            row.put("booked", s.getBookedCount());
            row.put("capacity", s.getActualCapacity());
            row.put("occupancyRate", s.getActualCapacity() > 0
                    ? Math.round(s.getBookedCount() * 100.0 / s.getActualCapacity()) : 0);
            result.add(row);
        }
        return result;
    }

    public List<RenewalRecord> memberRenewals(Long memberId) {
        return renewalRecordMapper.selectList(
                new LambdaQueryWrapper<RenewalRecord>()
                        .eq(RenewalRecord::getMemberId, memberId)
                        .orderByDesc(RenewalRecord::getRenewalDate));
    }
}
