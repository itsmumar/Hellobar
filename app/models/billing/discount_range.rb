# Struct for holding discount information
# Params
# slots - number of subscriptions that this tier can hold
# tier - index of the tier, higher index is applied later
# monthly - amount to discount for a monthly subscriptions
# yearly - amount to discount for a yearly subscriptions
DiscountRange = Struct.new(:slots, :tier, :monthly, :yearly)
