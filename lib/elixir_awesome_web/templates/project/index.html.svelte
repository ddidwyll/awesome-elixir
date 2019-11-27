<header>
  <img
    alt="Awesome Elixir"
    src="https://user-images.githubusercontent.com/1716442/34649486-006db6a4-f3b9-11e7-93bc-d7941080dc44.png">
  <h1>Awesome Elixir<sup>js</sup></h1>
  <figure>
    <nav>
      <a
        disabled
        class="button button-outline"
        href="/?search={search}"
      >all</a>
      <a
        disabled
        class="button button-outline"
        href="/?search={search}&min_stars=0"
      >≥0☆</a>
      <a
        disabled
        class="button button-outline"
        href="/?search={search}&min_stars=10"
      >≥10☆</a>
      <a
        disabled
        class="button button-outline"
        href="/?search={search}&min_stars=50"
      >≥50☆</a>
      <a
        disabled
        class="button button-outline"
        href="/?search={search}&min_stars=100"
      >≥100☆</a>
    </nav>
    <form>
      <input
        type="search"
        name="search"
        placeholder="Search"
        value="{search}"
      />
      <input
        type="hidden"
        name="min_stars"
        value="{stars}"
      />
      <input
        value="go"
        type="submit"
        class="button-outline"
      />
    </form>
  </figure>
</header>
<hr>

<nav>
  <ul>
    {#each cats as cat}
      <li>
        <a
          disabled
          href="#{cat.name}"
        >
            {@html cat.name}
          <sup>{cat.projects}</sup>
        </a>
      </li>
    {/each}
  </ul>
</nav>

{#each cats as cat}
  {#if cat.projects > 0}
    <section id="{cat.name}">
      <a href="#top">top</a>
      <h2>{@html cat.name}</h2>
      <hr>
      {@html cat.description}
      <ul>
        {#each cat.projects as project}
          <li>
            <div>
              <a href="{project.url}" target="_blank">
                {@html project.name}
              </a>
              {#if project.stars_count > -1}
                <small title="Repo stars">
                  {project.stars_count}☆&nbsp;
                </small>
              {/if}
              {#if project.last_commit}
                <small title="Last commit">
                  {project.last_commit}
                </small>
              {/if}
            </div>
            <hr>
            {@html project.description}
          </li>
        {/each}
      </ul>
    </section>
  {/if}
{/each}

<script>
  export let cats = []

  const stars = null
  const search = ""
</script>
