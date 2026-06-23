const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }
    if (request.method !== 'POST') return json({ error: 'Not found' }, 404);

    try {
      const payload = await request.json();
      if (payload.website) return json({ ok: true });

      const title = clean(payload.title, 120);
      const description = clean(payload.description, 5000);
      const steps = clean(payload.steps, 3000);
      const expected = clean(payload.expected, 2000);
      const contact = clean(payload.contact, 200);
      const appVersion = clean(payload.appVersion, 50);
      const platform = clean(payload.platform, 100);

      if (title.length < 5 || description.length < 10) {
        return json({ error: 'Title and description are required.' }, 400);
      }

      const body = [
        '## Description', description,
        '## Steps to reproduce', steps || 'Not provided',
        '## Expected result', expected || 'Not provided',
        '## App details', `- Version: ${appVersion || 'Unknown'}\n- Platform: ${platform || 'Unknown'}`,
        contact ? `## Contact (optional)\n${contact}` : '',
        '_Submitted from the Watchio in-app bug reporter._',
      ].filter(Boolean).join('\n\n');

      const response = await fetch(
        `https://api.github.com/repos/${env.GITHUB_OWNER}/${env.GITHUB_REPO}/issues`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${env.GITHUB_TOKEN}`,
            Accept: 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent': 'Watchio-Bug-Reporter',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ title: `[Bug] ${title}`, body, labels: ['bug'] }),
        },
      );

      const result = await response.json();
      if (!response.ok) {
        console.error('GitHub issue failure', response.status, result.message);
        return json(
          {
            error: 'Could not create issue.',
            status: response.status,
            detail: result.message || 'GitHub rejected the request.',
          },
          502,
        );
      }
      return json({ ok: true, issue: result.number });
    } catch (error) {
      console.error(error);
      return json({ error: 'Invalid request.' }, 400);
    }
  },
};

function clean(value, maxLength) {
  return typeof value === 'string' ? value.trim().slice(0, maxLength) : '';
}

function json(value, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
