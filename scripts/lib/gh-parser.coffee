ghParser =
  parsePullRequests: (body) ->
    data = JSON.parse(body)
    this.pullRequest(pr) for pr in data["data"]["user"]["pullRequests"]["nodes"]

  parseReviewRequests: (body, login) ->
    data = JSON.parse(body)
    reviews = []
    for repo in data["data"]["organization"]["repositories"]["nodes"]
      for pr in repo["pullRequests"]["nodes"]
        prReviews = {
          title: pr["title"]
          url: pr["url"]
          review: {}
        }
        for reviewRequest in pr["reviewRequests"]["nodes"]
          prReviews.review = { state: "PENDING" } if reviewRequest["reviewer"]["login"] == login
        for review in pr["reviews"]["nodes"]
          prReviews.review = { state: review["state"], createdAt: review["createdAt"] }
        reviews.push prReviews if prReviews.review.state
    reviews

  pullRequest: (pr) ->
    {
      createdAt: pr["createdAt"]
      labels: label["name"] for label in pr["labels"]["nodes"]
      reviews: this.reviews(pr["reviews"]["nodes"], pr["reviewRequests"]["nodes"])
      status: this.status(pr["commits"]["nodes"][0]["commit"]["status"])
      title: pr["title"]
      url: pr["url"]
    }

  reviews: (reviews, requests) ->
    a = {}
    a[review["author"]["login"]] = { state: review["state"], createdAt: review["createdAt"] } for review in reviews
    a[request["reviewer"]["login"]] = { state: "PENDING" } for request in requests
    a

  status: (status) ->
    if status then status["state"] else "UNKNOWN"

module.exports = ghParser
