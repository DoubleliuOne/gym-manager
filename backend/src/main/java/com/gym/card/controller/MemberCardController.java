package com.gym.card.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.gym.card.entity.CardTemplate;
import com.gym.card.entity.MemberCard;
import com.gym.card.entity.RenewalRecord;
import com.gym.card.mapper.RenewalRecordMapper;
import com.gym.card.service.CardTemplateService;
import com.gym.card.service.MemberCardService;
import com.gym.common.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/cards")
@RequiredArgsConstructor
public class MemberCardController {

    private final MemberCardService memberCardService;
    private final CardTemplateService templateService;
    private final RenewalRecordMapper renewalRecordMapper;

    @PostMapping("/issue")
    public Result<MemberCard> issue(@RequestBody Map<String, Object> body) {
        Long memberId = Long.valueOf(body.get("memberId").toString());
        Long templateId = Long.valueOf(body.get("templateId").toString());
        return Result.success(memberCardService.issueCard(memberId, templateId));
    }

    @PostMapping("/purchase")
    public Result<MemberCard> purchase(@RequestBody Map<String, Object> body) {
        Long memberId = Long.valueOf(body.get("memberId").toString());
        Long templateId = Long.valueOf(body.get("templateId").toString());
        MemberCard card = memberCardService.issueCard(memberId, templateId);
        CardTemplate template = templateService.getById(templateId);
        RenewalRecord record = new RenewalRecord();
        record.setMemberId(memberId);
        record.setCardId(card.getId());
        record.setTemplateId(templateId);
        record.setAmount(template.getPrice());
        record.setPaymentMethod(0);
        record.setNewEndDate(card.getEndDate());
        renewalRecordMapper.insert(record);
        return Result.success(card);
    }

    @GetMapping("/renewals")
    public Result<Object> renewals(@RequestParam Long memberId) {
        return Result.success(renewalRecordMapper.selectList(
                new LambdaQueryWrapper<RenewalRecord>()
                        .eq(RenewalRecord::getMemberId, memberId)
                        .orderByDesc(RenewalRecord::getRenewalDate)));
    }

    @PutMapping("/{id}/disable")
    public Result<Void> disable(@PathVariable Long id) {
        MemberCard card = memberCardService.getById(id);
        if (card == null) { return Result.error("会员卡不存在"); }
        card.setStatus(3);
        memberCardService.updateById(card);
        return Result.success();
    }

    @PutMapping("/{id}/reactivate")
    public Result<Void> reactivate(@PathVariable Long id) {
        MemberCard card = memberCardService.getById(id);
        if (card == null) { return Result.error("会员卡不存在"); }
        if (card.getStatus() != 3) { return Result.error("只有已停用的卡可以重启"); }
        card.setStatus(0);
        memberCardService.updateById(card);
        return Result.success();
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        renewalRecordMapper.delete(new LambdaQueryWrapper<RenewalRecord>().eq(RenewalRecord::getCardId, id));
        memberCardService.removeById(id);
        return Result.success();
    }
}
