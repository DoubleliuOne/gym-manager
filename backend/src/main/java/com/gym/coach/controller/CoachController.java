package com.gym.coach.controller;

import com.gym.coach.entity.Coach;
import com.gym.coach.service.CoachService;
import com.gym.common.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/coaches")
@RequiredArgsConstructor
public class CoachController {

    private final CoachService coachService;

    @GetMapping
    public Result<List<Coach>> list() {
        return Result.success(coachService.list());
    }

    @GetMapping("/{id}")
    public Result<Coach> getById(@PathVariable Long id) {
        return Result.success(coachService.getById(id));
    }

    @PostMapping
    public Result<Coach> create(@RequestBody Coach coach) {
        coachService.save(coach);
        return Result.success(coach);
    }

    @PutMapping("/{id}")
    public Result<Coach> update(@PathVariable Long id, @RequestBody Coach coach) {
        coach.setId(id);
        coachService.updateById(coach);
        return Result.success(coachService.getById(id));
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        coachService.removeById(id);
        return Result.success();
    }

    @GetMapping("/{id}/students")
    public Result<Object> getStudents(@PathVariable Long id) {
        return Result.success(coachService.getStudents(id));
    }
}
