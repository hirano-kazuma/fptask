module StaticPagesHelper
  # ページごとのtitleを返す
  def full_title(page_title = "")
    base_title = "FP予約管理システム"
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end
end
