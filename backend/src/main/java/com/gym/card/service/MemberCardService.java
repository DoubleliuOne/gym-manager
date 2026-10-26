package com.gym.card.service;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gym.card.entity.CardTemplate;
import com.gym.card.entity.MemberCard;
import com.gym.card.entity.RenewalRecord;
import com.gym.card.mapper.MemberCardMapper;
import com.gym.card.mapper.RenewalRecordMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDate;

@Service
@RequiredArgsConstructor
public class MemberCardService extends ServiceImpl<MemberCardMapper, MemberCard> {

    private final CardTemplateService templateService;
    private final RenewalRecordMapper renewalRecordMapper;

    @Transactional(rollbackFor = Exception.class)
    public MemberCard issueCard(Long memberId, Long templateId) {
        CardTemplate template = templateService.getById(templateId);
        if (template == null) {
            throw new IllegalArgumentException("卡类型不存在");
        }
        MemberCard card = new MemberCard();
        card.setMemberId(memberId);
        card.setTemplateId(templateId);
        card.setStartDate(LocalDate.now());

        Integer durationDays = template.getDurationDays();
        if (durationDays == null) { durationDays = 30; }
        if (template.getType() == 0) {
            card.setEndDate(LocalDate.now().plusDays(durationDays));
            card.setRemainingCount(-1);
        } else {
            Integer totalCount = template.getTotalCount();
            if (totalCount == null) { totalCount = 1; }
            card.setEndDate(LocalDate.now().plusDays(durationDays));
            card.setRemainingCount(totalCount);
        }
        card.setStatus(0);
        save(card);
        return card;
    }

    @Transactional(rollbackFor = Exception.class)
    public RenewalRecord renew(Long memberId, Long cardId, Long templateId,
                               BigDecimal amount, Integer paymentMethod, String remark) {
        MemberCard card = getById(cardId);
        if (card == null || !card.getMemberId().equals(memberId)) {
            throw new IllegalArgumentException("会员卡不存在");
        }
        CardTemplate template = templateService.getById(templateId);
        if (template == null) {
            throw new IllegalArgumentException("卡类型不存在");
        }
        LocalDate oldEnd = card.getEndDate();
        LocalDate baseDate = oldEnd.isAfter(LocalDate.now()) ? oldEnd.plusDays(1) : LocalDate.now();
        LocalDate newEnd;
        if (template.getType() == 0) {
            newEnd = baseDate.plusDays(template.getDurationDays());
            card.setEndDate(newEnd);
            card.setStatus(0);
        } else {
            newEnd = baseDate.plusDays(template.getDurationDays());
            card.setEndDate(newEnd);
            card.setRemainingCount((card.getRemainingCount() != null ? card.getRemainingCount() : 0) + template.getTotalCount());
            card.setStatus(0);
        }
        updateById(card);
        RenewalRecord record = new RenewalRecord();
        record.setMemberId(memberId);
        record.setCardId(cardId);
        record.setTemplateId(templateId);
        record.setAmount(amount);
        record.setPaymentMethod(paymentMethod);
        record.setOldEndDate(oldEnd);
        record.setNewEndDate(newEnd);
        record.setRemark(remark);
        renewalRecordMapper.insert(record);
        return record;
    }
}
