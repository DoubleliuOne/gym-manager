package com.gym.booking.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("booking")
public class Booking {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long memberId;
    private Long cardId;
    private Long scheduleId;
    private Integer status;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime bookedAt;
    private LocalDateTime checkedInAt;
    private LocalDateTime cancelledAt;
}
