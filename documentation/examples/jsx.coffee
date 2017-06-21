renderStarRating = ({ rating, maxStars }) ->
  <aside title={"Rating: #{rating} of #{maxStars} stars"}>
    {for [0...Math.floor(rating)]
      <Star className="wholeStar" />}
    {if rating % 1 isnt 0
      <Star className="halfStar" />}
    {for [Math.ceil(rating)...maxStars]
      <Star className="emptyStar" />}
  </aside>
