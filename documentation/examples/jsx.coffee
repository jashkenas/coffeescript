renderStarRating = ({ rating, maxStars }) ->
  <aside title={"Rating: #{rating} of #{maxStars} stars"}>{
    for wholeStars in [0...Math.floor(rating)]
      <Star className="wholeStar" />
    if rating % 1 isnt 0
      <Star className="halfStar" />
    for emptyStars in [Math.ceil(rating)...maxStars]
      <Star className="emptyStar" />
  }</aside>
