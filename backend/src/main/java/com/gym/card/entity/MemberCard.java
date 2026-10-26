package com.gym.card.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("member_card")
public class MemberCard {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long memberId;
    private Long templateId;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer remainingCount;
    private Integer status;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
