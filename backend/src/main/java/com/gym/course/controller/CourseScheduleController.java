package com.gym.course.controller;

import com.gym.common.Result;
import com.gym.course.entity.CourseSchedule;
import com.gym.course.service.CourseScheduleService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/schedules")
@RequiredArgsConstructor
public class CourseScheduleController {

    private final CourseScheduleService scheduleService;

    @GetMapping
    public Result<List<CourseSchedule>> list(@RequestParam(required = false) String date,
                                              @RequestParam(required = false) Long coachId) {
        if (date != null && coachId != null) {
            return Result.success(scheduleService.lambdaQuery()
                    .eq(CourseSchedule::getClassDate, LocalDate.parse(date))
                    .eq(CourseSchedule::getCoachId, coachId)
                    .eq(CourseSchedule::getStatus, 0)
                    .orderByAsc(CourseSchedule::getStartTime).list());
        }
        if (date != null) {
            return Result.success(scheduleService.getSchedulesByDate(LocalDate.parse(date)));
        }
        if (coachId != null) {
            return Result.success(scheduleService.lambdaQuery()
                    .eq(CourseSchedule::getCoachId, coachId)
                    .ge(CourseSchedule::getClassDate, LocalDate.now())
                    .eq(CourseSchedule::getStatus, 0)
                    .orderByAsc(CourseSchedule::getClassDate, CourseSchedule::getStartTime).list());
        }
        return Result.success(scheduleService.getAvailableSchedules());
    }

    @GetMapping("/{id}")
    public Result<CourseSchedule> getById(@PathVariable Long id) {
        return Result.success(scheduleService.getById(id));
    }

    @PostMapping
    public Result<CourseSchedule> create(@RequestBody CourseSchedule schedule) {
        scheduleService.validateSchedule(schedule, null);
        scheduleService.save(schedule);
       return Result.success(schedule);
   }

    @PutMapping("/{id}")
    public Result<CourseSchedule> update(@PathVariable Long id, @RequestBody CourseSchedule schedule) {
        schedule.setId(id);
        scheduleService.validateSchedule(schedule, id);
        scheduleService.updateById(schedule);
       return Result.success(scheduleService.getById(id));
   }

    @DeleteMapping("/{id}")
    public Result<Void> cancel(@PathVariable Long id) {
        scheduleService.lambdaUpdate().eq(CourseSchedule::getId, id)
                .set(CourseSchedule::getStatus, 1).update();
        return Result.success();
    }
}
