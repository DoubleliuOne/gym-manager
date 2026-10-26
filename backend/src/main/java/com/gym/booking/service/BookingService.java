package com.gym.booking.service;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gym.booking.entity.Booking;
import com.gym.booking.entity.CheckIn;
import com.gym.booking.mapper.BookingMapper;
import com.gym.booking.mapper.CheckInMapper;
import com.gym.card.entity.MemberCard;
import com.gym.card.mapper.MemberCardMapper;
import com.gym.course.entity.CourseSchedule;
import com.gym.course.mapper.CourseScheduleMapper;
import com.gym.member.entity.Member;
import com.gym.member.mapper.MemberMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class BookingService extends ServiceImpl<BookingMapper, Booking> {

    private final MemberMapper memberMapper;
    private final CourseScheduleMapper scheduleMapper;
    private final MemberCardMapper memberCardMapper;
    private final CheckInMapper checkInMapper;

    @Transactional(rollbackFor = Exception.class)
    public Booking reserve(Long memberId, Long scheduleId) {
        Member member = memberMapper.selectById(memberId);
        if (member == null || member.getStatus() != 0) {
            throw new IllegalArgumentException("会员不存在或已冻结");
        }

        CourseSchedule schedule = scheduleMapper.selectById(scheduleId);
        if (schedule == null || schedule.getStatus() != 0) {
            throw new IllegalArgumentException("课程不存在或已取消");
        }

        MemberCard validCard = findValidCard(memberId);
        if (validCard == null) {
            throw new IllegalArgumentException("没有有效的会员卡，请先续费");
        }

        List<Booking> existing = baseMapper.selectList(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<Booking>()
                .eq(Booking::getMemberId, memberId)
                .in(Booking::getStatus, 0, 1));
        for (Booking b : existing) {
            CourseSchedule bookedSchedule = scheduleMapper.selectById(b.getScheduleId());
            if (bookedSchedule != null
                    && bookedSchedule.getClassDate().equals(schedule.getClassDate())
                    && isTimeOverlap(bookedSchedule.getStartTime(), bookedSchedule.getEndTime(),
                    schedule.getStartTime(), schedule.getEndTime())) {
                throw new IllegalArgumentException("与已有预约时间冲突");
            }
        }

        int updated = scheduleMapper.update(null, new LambdaUpdateWrapper<CourseSchedule>()
                .eq(CourseSchedule::getId, scheduleId)
                .eq(CourseSchedule::getVersion, schedule.getVersion())
                .apply("booked_count < actual_capacity")
                .setSql("booked_count = booked_count + 1, version = version + 1"));
        if (updated == 0) {
            throw new IllegalArgumentException("课程已满或已被其他人预约，请刷新后重试");
        }

        Booking booking = new Booking();
        booking.setMemberId(memberId);
        booking.setCardId(validCard.getId());
        booking.setScheduleId(scheduleId);
        booking.setStatus(0);
        baseMapper.insert(booking);

        return booking;
    }

    @Transactional(rollbackFor = Exception.class)
    public void cancel(Long bookingId, Long memberId) {
        Booking booking = baseMapper.selectById(bookingId);
        if (booking == null || !booking.getMemberId().equals(memberId)) {
            throw new IllegalArgumentException("预约记录不存在");
        }
        if (booking.getStatus() != 0) {
            throw new IllegalArgumentException("当前预约状态无法取消");
        }
        booking.setStatus(2);
        booking.setCancelledAt(java.time.LocalDateTime.now());
        baseMapper.updateById(booking);

        scheduleMapper.update(null, new LambdaUpdateWrapper<CourseSchedule>()
                .eq(CourseSchedule::getId, booking.getScheduleId())
                .gt(CourseSchedule::getBookedCount, 0)
                .setSql("booked_count = booked_count - 1"));
    }

    @Transactional(rollbackFor = Exception.class)
    public CheckIn checkIn(Long bookingId, Integer method) {
        Booking booking = baseMapper.selectById(bookingId);
        if (booking == null || booking.getStatus() != 0) {
            throw new IllegalArgumentException("预约记录不存在或已处理");
        }
        booking.setStatus(1);
        booking.setCheckedInAt(java.time.LocalDateTime.now());
        baseMapper.updateById(booking);

        CheckIn checkIn = new CheckIn();
        checkIn.setBookingId(bookingId);
        checkIn.setMemberId(booking.getMemberId());
        checkIn.setScheduleId(booking.getScheduleId());
        checkIn.setMethod(method != null ? method : 0);
        checkInMapper.insert(checkIn);

        if (booking.getCardId() != null) {
            memberCardMapper.update(null, new LambdaUpdateWrapper<MemberCard>()
                    .eq(MemberCard::getId, booking.getCardId())
                    .gt(MemberCard::getRemainingCount, 0)
                    .setSql("remaining_count = remaining_count - 1"));
        }
        return checkIn;
    }

    public MemberCard findValidCard(Long memberId) {
        List<MemberCard> cards = memberCardMapper.selectList(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<MemberCard>()
                .eq(MemberCard::getMemberId, memberId)
                .eq(MemberCard::getStatus, 0));
        for (MemberCard card : cards) {
            boolean expired = card.getEndDate() != null && card.getEndDate().isBefore(LocalDate.now());
            // -1 means time-based card (unlimited uses within period); 0 means count-based card used up
            boolean usedUp = card.getRemainingCount() != null && card.getRemainingCount() == 0;
            if (expired || usedUp) {
                card.setStatus(expired ? 1 : 2);
                memberCardMapper.updateById(card);
                continue;
            }
            return card;
        }
        return null;
    }

    private boolean isTimeOverlap(LocalTime s1, LocalTime e1, LocalTime s2, LocalTime e2) {
        return s1.isBefore(e2) && e1.isAfter(s2);
    }
}
