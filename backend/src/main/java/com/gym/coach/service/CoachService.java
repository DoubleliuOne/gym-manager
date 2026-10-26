package com.gym.coach.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gym.booking.entity.Booking;
import com.gym.booking.mapper.BookingMapper;
import com.gym.coach.entity.Coach;
import com.gym.coach.mapper.CoachMapper;
import com.gym.course.entity.CourseSchedule;
import com.gym.course.mapper.CourseScheduleMapper;
import com.gym.member.entity.Member;
import com.gym.member.mapper.MemberMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CoachService extends ServiceImpl<CoachMapper, Coach> {

    private final CourseScheduleMapper scheduleMapper;
    private final BookingMapper bookingMapper;
    private final MemberMapper memberMapper;

    private static final String HASH_ALGORITHM = "SHA-256";
    private static final int SALT_LENGTH = 16;

    private String hashPassword(String rawPassword, byte[] salt) {
        try {
            MessageDigest md = MessageDigest.getInstance(HASH_ALGORITHM);
            md.update(salt);
            byte[] hash = md.digest(rawPassword.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(salt) + ":" + Base64.getEncoder().encodeToString(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Password hashing failed", e);
        }
    }

    private boolean verifyPassword(String rawPassword, String storedHash) {
        String[] parts = storedHash.split(":");
        if (parts.length != 2) return false;
        try {
            byte[] salt = Base64.getDecoder().decode(parts[0]);
            MessageDigest md = MessageDigest.getInstance(HASH_ALGORITHM);
            md.update(salt);
            byte[] hash = md.digest(rawPassword.getBytes(StandardCharsets.UTF_8));
            return parts[1].equals(Base64.getEncoder().encodeToString(hash));
        } catch (NoSuchAlgorithmException | IllegalArgumentException e) {
            return false;
        }
    }

    public void register(String phone, String password, String name, String specialty) {
        Coach existing = lambdaQuery().eq(Coach::getPhone, phone).one();
        if (existing != null) {
            throw new IllegalArgumentException("该手机号已注册");
        }
        SecureRandom random = new SecureRandom();
        byte[] salt = new byte[SALT_LENGTH];
        random.nextBytes(salt);

        Coach coach = new Coach();
        coach.setPhone(phone);
        coach.setPasswordHash(hashPassword(password, salt));
        coach.setName(name);
        coach.setSpecialty(specialty);
        coach.setStatus(0);
        save(coach);
    }

    public Coach createFromMember(Long memberId, String phone, String passwordHash, String name, String specialty) {
        Coach existing = lambdaQuery().eq(Coach::getPhone, phone).one();
        if (existing == null) {
            Coach coach = new Coach();
            coach.setPhone(phone);
            coach.setPasswordHash(passwordHash);
            coach.setName(name);
            coach.setSpecialty(specialty != null ? specialty : "");
            coach.setStatus(0);
            save(coach);
            return coach;
        }
        return existing;
    }

    public Coach login(String phone, String password) {
        Coach coach = lambdaQuery().eq(Coach::getPhone, phone).one();
        if (coach == null) {
            throw new IllegalArgumentException("账号不存在");
        }
        if (coach.getPasswordHash() == null || !verifyPassword(password, coach.getPasswordHash())) {
            throw new IllegalArgumentException("密码错误");
        }
        return coach;
    }

    public List<Map<String, Object>> getStudents(Long coachId) {
        List<CourseSchedule> schedules = scheduleMapper.selectList(
                new LambdaQueryWrapper<CourseSchedule>()
                        .eq(CourseSchedule::getCoachId, coachId)
                        .eq(CourseSchedule::getStatus, 0));
        if (schedules.isEmpty()) {
            return new ArrayList<>();
        }
        Set<Long> scheduleIds = schedules.stream().map(CourseSchedule::getId).collect(Collectors.toSet());
        List<Booking> bookings = bookingMapper.selectList(
                new LambdaQueryWrapper<Booking>()
                        .in(Booking::getScheduleId, scheduleIds)
                        .in(Booking::getStatus, 0, 1));
        if (bookings.isEmpty()) {
            return new ArrayList<>();
        }
        Set<Long> memberIds = bookings.stream().map(Booking::getMemberId).collect(Collectors.toSet());
        List<Member> members = memberMapper.selectBatchIds(memberIds);
        List<Map<String, Object>> result = new ArrayList<>();
        for (Member m : members) {
            Map<String, Object> row = new HashMap<>();
            row.put("id", m.getId());
            row.put("name", m.getName());
            row.put("phone", m.getPhone());
            row.put("gender", m.getGender());
            result.add(row);
        }
        return result;
    }
}
