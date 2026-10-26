package com.gym.booking.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.gym.booking.entity.Booking;
import com.gym.booking.entity.CheckIn;
import com.gym.booking.mapper.CheckInMapper;
import com.gym.booking.service.BookingService;
import com.gym.common.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/bookings")
@RequiredArgsConstructor
public class BookingController {

    private final BookingService bookingService;
    private final CheckInMapper checkInMapper;

    @GetMapping
    public Result<List<Booking>> list(@RequestParam(required = false) Long memberId,
                                      @RequestParam(required = false) Long scheduleId) {
        LambdaQueryWrapper<Booking> wrapper = new LambdaQueryWrapper<>();
        if (memberId != null) wrapper.eq(Booking::getMemberId, memberId);
        if (scheduleId != null) wrapper.eq(Booking::getScheduleId, scheduleId);
        wrapper.orderByDesc(Booking::getBookedAt);
        return Result.success(bookingService.list(wrapper));
    }

    @PostMapping
    public Result<Booking> reserve(@RequestBody Map<String, Object> body) {
        Long memberId = Long.valueOf(body.get("memberId").toString());
        Long scheduleId = Long.valueOf(body.get("scheduleId").toString());
        return Result.success(bookingService.reserve(memberId, scheduleId));
    }

    @PutMapping("/{id}/cancel")
    public Result<Void> cancel(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long memberId = Long.valueOf(body.get("memberId").toString());
        bookingService.cancel(id, memberId);
        return Result.success();
    }

    @PostMapping("/checkin")
    public Result<CheckIn> checkIn(@RequestBody Map<String, Object> body) {
        Long bookingId = Long.valueOf(body.get("bookingId").toString());
        Integer method = body.containsKey("method") ? Integer.valueOf(body.get("method").toString()) : 0;
        return Result.success(bookingService.checkIn(bookingId, method));
    }

    @GetMapping("/checkins")
    public Result<List<CheckIn>> checkInList(@RequestParam(required = false) Long memberId) {
        LambdaQueryWrapper<CheckIn> wrapper = new LambdaQueryWrapper<>();
        if (memberId != null) wrapper.eq(CheckIn::getMemberId, memberId);
        wrapper.orderByDesc(CheckIn::getCheckInTime);
        return Result.success(checkInMapper.selectList(wrapper));
    }

    @GetMapping("/member/{memberId}")
    public Result<List<Booking>> myBookings(@PathVariable Long memberId) {
        return Result.success(bookingService.list(
                new LambdaQueryWrapper<Booking>()
                        .eq(Booking::getMemberId, memberId)
                        .orderByDesc(Booking::getBookedAt)));
    }
}
