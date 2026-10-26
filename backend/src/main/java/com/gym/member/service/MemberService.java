package com.gym.member.service;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gym.member.entity.Member;
import com.gym.member.mapper.MemberMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;

@Service
@RequiredArgsConstructor
public class MemberService extends ServiceImpl<MemberMapper, Member> {

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

    public void register(String phone, String password, String name) {
        Member existing = lambdaQuery().eq(Member::getPhone, phone).one();
        if (existing != null) {
            throw new IllegalArgumentException("该手机号已注册");
        }
        SecureRandom random = new SecureRandom();
        byte[] salt = new byte[SALT_LENGTH];
        random.nextBytes(salt);

        Member member = new Member();
        member.setPhone(phone);
        member.setPasswordHash(hashPassword(password, salt));
        member.setName(name);
        member.setStatus(0);
        save(member);
    }

    public Member login(String phone, String password) {
        Member member = lambdaQuery().eq(Member::getPhone, phone).one();
        if (member == null) {
            throw new IllegalArgumentException("账号不存在");
        }
        if (!verifyPassword(password, member.getPasswordHash())) {
            throw new IllegalArgumentException("密码错误");
        }
        return member;
    }
}
