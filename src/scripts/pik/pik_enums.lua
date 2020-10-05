-- Define enums
FamiliarVariant.PIK = Isaac.GetEntityVariantByName("Pik")

PikState = {
    APPEAR = 0,
    DISMISS_IDLE = 1,
    DISMISS_ACTIVATE = 2,
    ACTIVE_IDLE = 3,
    ACTIVE_FOLLOW = 4,
    ACTIVE_CHASE = 5,
    ACTIVE_ATTACK = 6,
    ACTIVE_SHAKEOFF = 7,
    ACTIVE_DISMISS = 8,
}