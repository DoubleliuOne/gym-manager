package com.gym.card.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("card_template")
public class CardTemplate {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String name;
    private Integer type;
    private Integer durationDays;
    private Integer totalCount;
    private BigDecimal price;
    private Integer status;
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
