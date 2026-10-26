package com.gym.course.controller;

import com.gym.common.Result;
import com.gym.course.entity.Course;
import com.gym.course.service.CourseService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/courses")
@RequiredArgsConstructor
public class CourseController {

    private final CourseService courseService;

    @GetMapping
    public Result<List<Course>> list() {
        return Result.success(courseService.lambdaQuery().eq(Course::getStatus, 0).list());
    }

    @GetMapping("/{id}")
    public Result<Course> getById(@PathVariable Long id) {
        return Result.success(courseService.getById(id));
    }

    @PostMapping
    public Result<Course> create(@RequestBody Course course) {
        courseService.save(course);
        return Result.success(course);
    }

    @PutMapping("/{id}")
    public Result<Course> update(@PathVariable Long id, @RequestBody Course course) {
        course.setId(id);
        courseService.updateById(course);
        return Result.success(courseService.getById(id));
    }
}
