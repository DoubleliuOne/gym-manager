package com.gym.coach.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("coach")
public class Coach {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String name;
    private String phone;
    @JsonIgnore
    @TableField(exist = false)
    private String passwordHash;
    private String specialty;
    private String avatarUrl;
    private Integer status;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
