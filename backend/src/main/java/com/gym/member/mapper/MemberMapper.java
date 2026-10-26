package com.gym.member.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.gym.member.entity.Member;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface MemberMapper extends BaseMapper<Member> {
}
