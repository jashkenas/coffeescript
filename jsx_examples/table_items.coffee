%Table
  = for item in items
    {is_accessory, parentId, id} = item
    itemId = if is_accessory then parentId else id
    hidden = not allHidden and removedItemIds.indexOf(itemId) >= 0
    %ItemRow{
      key: id
      item
      quantityOverride: itemQuantityOverrides[itemId] or null
      className: 'js-Hiding is-hidden' if hidden
    }
