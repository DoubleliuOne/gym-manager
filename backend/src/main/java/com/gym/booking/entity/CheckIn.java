package com.gym.booking.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("check_in")
public class CheckIn {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long bookingId;
    private Long memberId;
    private Long scheduleId;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime checkInTime;
    private Integer method;
}
