renderStarRating = ({ rating, maxStars }) ->
  <aside title={"Rating: #{rating} of #{maxStars} stars"}>
    {for wholeStar in [0...Math.floor(rating)]
      <Star className="wholeStar" key={wholeStar} />}
    {if rating % 1 isnt 0
      <Star className="halfStar" />}
    {for emptyStar in [Math.ceil(rating)...maxStars]
      <Star className="emptyStar" key={emptyStar} />}
  </aside>
