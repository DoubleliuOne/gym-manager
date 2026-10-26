package com.gym.card.controller;

import com.gym.card.entity.CardTemplate;
import com.gym.card.service.CardTemplateService;
import com.gym.common.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/cards/templates")
@RequiredArgsConstructor
public class CardTemplateController {

    private final CardTemplateService cardTemplateService;

    @GetMapping
    public Result<List<CardTemplate>> list() {
        return Result.success(cardTemplateService.list());
    }

    @PostMapping
    public Result<CardTemplate> create(@RequestBody CardTemplate template) {
        cardTemplateService.save(template);
        return Result.success(template);
    }

    @PutMapping("/{id}")
    public Result<CardTemplate> update(@PathVariable Long id, @RequestBody CardTemplate template) {
        template.setId(id);
        cardTemplateService.updateById(template);
        return Result.success(cardTemplateService.getById(id));
    }
}
