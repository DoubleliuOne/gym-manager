package com.gym.card.service;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gym.card.entity.CardTemplate;
import com.gym.card.mapper.CardTemplateMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CardTemplateService extends ServiceImpl<CardTemplateMapper, CardTemplate> {
}
