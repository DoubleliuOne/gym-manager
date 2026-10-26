package com.gym.course.service;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gym.course.entity.Course;
import com.gym.course.mapper.CourseMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CourseService extends ServiceImpl<CourseMapper, Course> {
}
