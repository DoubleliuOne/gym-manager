package com.gym.course.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalTime;

@Data
@TableName("course_schedule")
public class CourseSchedule {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long courseId;
    private Long coachId;
    private LocalDate classDate;
    private LocalTime startTime;
    private LocalTime endTime;
    private Integer actualCapacity;
    private Integer bookedCount;
    private Integer status;
    private String remark;
    @Version
    private Integer version;
}
