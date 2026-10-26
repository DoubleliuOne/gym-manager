package com.gym.statistics.controller;

import com.gym.common.Result;
import com.gym.statistics.service.StatisticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/statistics")
@RequiredArgsConstructor
public class StatisticsController {

    private final StatisticsService statisticsService;

    @GetMapping("/dashboard")
    public Result<Map<String, Object>> dashboard() {
        return Result.success(statisticsService.dashboard());
    }

    @GetMapping("/course-bookings")
    public Result<List<Map<String, Object>>> courseBookings(
            @RequestParam String start, @RequestParam String end) {
        return Result.success(statisticsService.courseBookingStats(
                LocalDate.parse(start), LocalDate.parse(end)));
    }

    @GetMapping("/member-renewals")
    public Result<Object> memberRenewals(@RequestParam Long memberId) {
        return Result.success(statisticsService.memberRenewals(memberId));
    }
}
