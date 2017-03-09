Issue.seed_once(:slug) do |s|
  s.title = Issue::TITLE_OF_PARTI_PARTI
  s.slug = Issue::SLUG_OF_PARTI_PARTI
  s.group_slug = Group::SLUG_OF_UNION
end
