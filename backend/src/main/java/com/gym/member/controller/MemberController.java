package com.gym.member.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.gym.card.entity.MemberCard;
import com.gym.card.mapper.MemberCardMapper;
import com.gym.common.Result;
import com.gym.member.entity.Member;
import com.gym.member.mapper.MemberMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/members")
@RequiredArgsConstructor
public class MemberController {

    private final MemberMapper memberMapper;
    private final MemberCardMapper memberCardMapper;

    @GetMapping
    public Result<Map<String, Object>> list(@RequestParam(defaultValue = "1") int page,
                                            @RequestParam(defaultValue = "20") int size,
                                            @RequestParam(required = false) String keyword) {
        if (page < 1) page = 1;
        if (size < 1) size = 20;

        LambdaQueryWrapper<Member> queryWrapper = new LambdaQueryWrapper<>();
        if (keyword != null && !keyword.isEmpty()) {
            queryWrapper.like(Member::getName, keyword)
                    .or().like(Member::getPhone, keyword);
        }
        LambdaQueryWrapper<Member> countWrapper = new LambdaQueryWrapper<>();
        if (keyword != null && !keyword.isEmpty()) {
            countWrapper.like(Member::getName, keyword)
                    .or().like(Member::getPhone, keyword);
        }
        long total = memberMapper.selectCount(countWrapper);

        queryWrapper.orderByDesc(Member::getCreatedAt);
        List<Member> records = memberMapper.selectList(queryWrapper
                .last("LIMIT " + size + " OFFSET " + ((page - 1) * size)));

        Map<String, Object> result = new HashMap<>();
        result.put("records", records);
        result.put("total", total);
        result.put("page", page);
        result.put("size", size);
        return Result.success(result);
    }

    @GetMapping("/{id}")
    public Result<Member> getById(@PathVariable Long id) {
        return Result.success(memberMapper.selectById(id));
    }

    @PostMapping
    public Result<Member> create(@RequestBody Member member) {
        memberMapper.insert(member);
        return Result.success(member);
    }

    @PutMapping("/{id}")
    public Result<Member> update(@PathVariable Long id, @RequestBody Member member) {
        member.setId(id);
        memberMapper.updateById(member);
        return Result.success(memberMapper.selectById(id));
    }

    @PutMapping("/{id}/status")
    public Result<Void> updateStatus(@PathVariable Long id, @RequestBody Member member) {
        Member m = new Member();
        m.setId(id);
        m.setStatus(member.getStatus());
        memberMapper.updateById(m);
        return Result.success();
    }

    @GetMapping("/{id}/cards")
    public Result<List<MemberCard>> getCards(@PathVariable Long id) {
        return Result.success(memberCardMapper.selectList(
                new LambdaQueryWrapper<MemberCard>().eq(MemberCard::getMemberId, id)));
    }
}
