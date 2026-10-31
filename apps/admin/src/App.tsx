const metrics = [
  { label: 'Заведения', value: '—' },
  { label: 'На модерации', value: '—' },
  { label: 'Записи сегодня', value: '—' },
]

export function App() {
  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">Cosmetic Map</div>
        <nav><a className="active" href="#">Обзор</a><a href="#">Заведения</a><a href="#">Пользователи</a></nav>
      </aside>
      <main>
        <header><div><p className="eyebrow">Панель управления</p><h1>Добро пожаловать</h1></div><button>Добавить заведение</button></header>
        <section className="metrics">{metrics.map((metric) => <article key={metric.label}><span>{metric.label}</span><strong>{metric.value}</strong></article>)}</section>
        <section className="empty"><h2>Система готова к подключению данных</h2><p>Следующий этап — авторизация, CRUD заведений и модерация.</p></section>
      </main>
    </div>
  )
}

