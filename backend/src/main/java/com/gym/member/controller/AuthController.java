package com.gym.member.controller;

import com.gym.coach.entity.Coach;
import com.gym.coach.service.CoachService;
import com.gym.common.JwtUtil;
import com.gym.common.Result;
import com.gym.member.entity.Member;
import com.gym.member.service.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final MemberService memberService;
    private final CoachService coachService;
    private final JwtUtil jwtUtil;

    @PostMapping("/login")
    public Result<Map<String, Object>> login(@RequestBody Map<String, String> body) {
        Member member = memberService.login(body.get("phone"), body.get("password"));
        String source = body.getOrDefault("source", "");
        if ("admin".equals(source) && !Integer.valueOf(1).equals(member.getRole())) {
            return Result.error("该账号无管理员权限");
        }
        String token = jwtUtil.generateToken(member.getId(), "member");
        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("member", member);
        // 如果是教练，返回教练ID
        if (member.getRole() != null && member.getRole() == 2) {
            Coach coachRecord = coachService.lambdaQuery().eq(Coach::getPhone, member.getPhone()).one();
            if (coachRecord != null) {
                result.put("coachId", coachRecord.getId());
            }
        }
        return Result.success(result);
    }

    @PostMapping("/coach/login")
    public Result<Map<String, Object>> coachLogin(@RequestBody Map<String, String> body) {
        Coach coach = coachService.login(body.get("phone"), body.get("password"));
        String token = jwtUtil.generateToken(coach.getId(), "coach");
        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("coach", coach);
        return Result.success(result);
    }

    @PostMapping("/register")
    public Result<Void> register(@RequestBody Map<String, String> body) {
        String phone = body.get("phone");
        String password = body.get("password");
        String name = body.get("name");
        String role = body.getOrDefault("role", "member");

        if (phone == null || password == null || name == null) {
            return Result.error("手机号、密码和姓名不能为空");
        }

        if ("coach".equals(role)) {
            String specialty = body.getOrDefault("specialty", "");
            coachService.register(phone, password, name, specialty);
        } else {
            memberService.register(phone, password, name);
        }
        return Result.success();
    }

    @PostMapping("/profile-setup")
    public Result<Map<String, Object>> completeProfile(@RequestBody Map<String, Object> body) {
        try {
            Long memberId = Long.valueOf(body.get("memberId").toString());
            String role = body.getOrDefault("role", "member").toString();

            Member member = memberService.getById(memberId);
            if (member == null) {
                return Result.error("用户不存在");
            }

            if ("coach".equals(role)) {
                String specialty = body.getOrDefault("specialty", "").toString();
                String passwordHash = member.getPasswordHash();
                if (passwordHash == null) {
                    passwordHash = "";
                }
                coachService.createFromMember(memberId, member.getPhone(),
                        passwordHash, member.getName(), specialty);
                member.setRole(2);
                memberService.updateById(member);
            } else {
                Object genderObj = body.get("gender");
                if (genderObj != null) {
                    member.setGender(Integer.valueOf(genderObj.toString()));
                }
                Object birthdayObj = body.get("birthday");
                if (birthdayObj != null && !birthdayObj.toString().isEmpty()) {
                    member.setBirthday(LocalDate.parse(birthdayObj.toString()));
                }
                memberService.updateById(member);
            }

            String token = jwtUtil.generateToken(member.getId(), "member");
            Map<String, Object> result = new HashMap<>();
            result.put("token", token);
            result.put("member", member);
            return Result.success(result);
        } catch (Exception e) {
            String errMsg = e.getClass().getSimpleName() + ": " + (e.getMessage() != null ? e.getMessage() : "无详细消息");
            return Result.error(500, errMsg);
        }
    }
}
