package com.gym.card.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("renewal_record")
public class RenewalRecord {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long memberId;
    private Long cardId;
    private Long templateId;
    private BigDecimal amount;
    private Integer paymentMethod;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime renewalDate;
    private LocalDate oldEndDate;
    private LocalDate newEndDate;
    private String remark;
}
