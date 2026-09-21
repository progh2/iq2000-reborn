(() => {
  // 이전 README 기반 홈페이지의 북마크를 설치 안내로 이어 준다.
  let fragment = location.hash.slice(1);
  try { fragment = decodeURIComponent(fragment); } catch { /* Keep malformed fragments literal. */ }
  if (document.body.classList.contains('home') && location.hash &&
      !document.getElementById(fragment)) {
    location.replace(document.body.dataset.guideUrl + location.hash);
    return;
  }
  const main = document.querySelector('main');
  const toc = document.getElementById('page-toc');
  if (toc && main) {
    const list = document.createElement('ol');
    main.querySelectorAll('h2[id]').forEach(heading => {
      if (heading.textContent.trim() === '차례') return;
      const item = document.createElement('li');
      const link = document.createElement('a');
      link.href = '#' + encodeURIComponent(heading.id);
      link.textContent = heading.textContent;
      item.append(link);
      list.append(item);
    });
    if (list.childElementCount) { toc.append(list); toc.hidden = false; }
  }
  if (!navigator.clipboard?.writeText) return;
  main?.querySelectorAll('pre').forEach(pre => {
    const wrapper = document.createElement('div');
    wrapper.className = 'code-block';
    pre.before(wrapper);
    wrapper.append(pre);
    const button = document.createElement('button');
    button.className = 'copy-button';
    button.type = 'button';
    button.textContent = '복사';
    button.setAttribute('aria-label', '코드 복사');
    button.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(pre.textContent);
        button.textContent = '복사됨';
        document.getElementById('copy-status').textContent = '코드를 복사했습니다.';
      } catch {
        button.textContent = '직접 선택해 복사';
        document.getElementById('copy-status').textContent = '복사 권한이 없습니다. 코드를 직접 선택해 복사하세요.';
      }
      setTimeout(() => { button.textContent = '복사'; }, 2500);
    });
    wrapper.append(button);
  });
})();
