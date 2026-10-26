package com.gym.config;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.gym.member.entity.Member;
import com.gym.member.mapper.MemberMapper;
import com.gym.member.service.MemberService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class AdminInitializer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminInitializer.class);

    private final JdbcTemplate jdbcTemplate;
    private final MemberService memberService;
    private final MemberMapper memberMapper;

    @Override
    public void run(ApplicationArguments args) {
        try {
            jdbcTemplate.execute("ALTER TABLE member ADD COLUMN IF NOT EXISTS role SMALLINT DEFAULT 0");
            log.info("role column initialized");
        } catch (Exception e) {
            log.warn("role column may already exist: {}", e.getMessage());
        }

        try {
            jdbcTemplate.execute("ALTER TABLE coach ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) NOT NULL DEFAULT ''");
            log.info("coach password_hash column initialized");
        } catch (Exception e) {
            log.warn("coach password_hash may already exist: {}", e.getMessage());
        }

        Member admin = memberMapper.selectOne(
                new LambdaQueryWrapper<Member>().eq(Member::getPhone, "18800000000"));
        if (admin == null) {
            memberService.register("18800000000", "admin123", "超级管理员");
            admin = memberMapper.selectOne(
                    new LambdaQueryWrapper<Member>().eq(Member::getPhone, "18800000000"));
            if (admin != null) {
                admin.setRole(1);
                memberMapper.updateById(admin);
                log.info("Admin account created: 18800000000 / admin123");
            }
        } else {
            log.info("Admin account already exists");
        }

        Member mgr = memberMapper.selectOne(
                new LambdaQueryWrapper<Member>().eq(Member::getPhone, "13900000001"));
        if (mgr != null && mgr.getRole() == null) {
            mgr.setRole(1);
            memberMapper.updateById(mgr);
            log.info("Updated existing admin role");
        }

        log.info("AdminInitializer done");
    }
}
