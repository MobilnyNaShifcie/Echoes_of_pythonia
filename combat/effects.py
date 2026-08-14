from dataclasses import dataclass


@dataclass
class CombatEffects:
    enemy_defense_reduction: int = 0
    enemy_defense_actions_remaining: int = 0

    bleed_damage: int = 0
    bleed_turns_remaining: int = 0

    player_damage_reduction_percent: int = 0
    player_guard_hits_remaining: int = 0

    player_dodge_bonus: float = 0.0
    player_dodge_hits_remaining: int = 0

    @property
    def armor_break_active(self) -> bool:
        return self.enemy_defense_actions_remaining > 0

    @property
    def bleed_active(self) -> bool:
        return self.bleed_turns_remaining > 0 and self.bleed_damage > 0

    @property
    def guard_active(self) -> bool:
        return self.player_guard_hits_remaining > 0

    @property
    def dodge_active(self) -> bool:
        return self.player_dodge_hits_remaining > 0

    def effective_enemy_defense(self, base_defense: int) -> int:
        if not self.armor_break_active:
            return max(0, base_defense)
        return max(0, base_defense - self.enemy_defense_reduction)

    def consume_armor_break_action(self) -> None:
        if not self.armor_break_active:
            return
        self.enemy_defense_actions_remaining -= 1
        if self.enemy_defense_actions_remaining <= 0:
            self.enemy_defense_actions_remaining = 0
            self.enemy_defense_reduction = 0

    def apply_armor_break(self, reduction: int, actions: int) -> None:
        self.enemy_defense_reduction = max(
            self.enemy_defense_reduction,
            max(0, reduction),
        )
        self.enemy_defense_actions_remaining = max(
            self.enemy_defense_actions_remaining,
            max(0, actions),
        )

    def apply_bleed(self, damage: int, turns: int) -> None:
        self.bleed_damage = max(self.bleed_damage, max(0, damage))
        self.bleed_turns_remaining = max(
            self.bleed_turns_remaining,
            max(0, turns),
        )

    def consume_bleed_turn(self) -> None:
        if not self.bleed_active:
            return
        self.bleed_turns_remaining -= 1
        if self.bleed_turns_remaining <= 0:
            self.bleed_turns_remaining = 0
            self.bleed_damage = 0

    def apply_guard(self, reduction_percent: int, hits: int) -> None:
        self.player_damage_reduction_percent = max(
            self.player_damage_reduction_percent,
            max(0, min(reduction_percent, 90)),
        )
        self.player_guard_hits_remaining = max(
            self.player_guard_hits_remaining,
            max(0, hits),
        )

    def consume_guard_hit(self) -> None:
        if not self.guard_active:
            return
        self.player_guard_hits_remaining -= 1
        if self.player_guard_hits_remaining <= 0:
            self.player_guard_hits_remaining = 0
            self.player_damage_reduction_percent = 0

    def apply_dodge_bonus(self, bonus: float, hits: int) -> None:
        self.player_dodge_bonus = max(
            self.player_dodge_bonus,
            max(0.0, bonus),
        )
        self.player_dodge_hits_remaining = max(
            self.player_dodge_hits_remaining,
            max(0, hits),
        )

    def consume_dodge_hit(self) -> None:
        if not self.dodge_active:
            return
        self.player_dodge_hits_remaining -= 1
        if self.player_dodge_hits_remaining <= 0:
            self.player_dodge_hits_remaining = 0
            self.player_dodge_bonus = 0.0
