Issue.seed_once(:slug) do |s|
  s.title = '빠띠만든당'
  s.slug = Issue::SLUG_OF_PARTI_PARTI
  s.group_slug = Group::SLUG_OF_UNION
end

parti_parti = Issue.find_by(slug: Issue::SLUG_OF_PARTI_PARTI)
parti_parti.update_attributes!(group_slug: Group::SLUG_OF_UNION)
