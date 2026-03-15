# LLM Fundamentals

A hands-on, public learning path for understanding Large Language Models from first principles.

Inspired by the structure and rigor of Stanford CS336 (Spring 2025):
https://cs336.stanford.edu/spring2025/

## Course Map

1. [01_foundations_attention_embeddings.ipynb](./01_foundations_attention_embeddings.ipynb)
   - Why *Attention Is All You Need* matters
   - What embeddings are
   - Simple vector-space intuition with runnable code
2. [02_attention_mechanism.ipynb](./02_attention_mechanism.ipynb)
   - Query/Key/Value intuition
   - Scaled dot-product attention
   - Causal masking
3. [03_transformer_block.ipynb](./03_transformer_block.ipynb)
   - Residual connections and layer norm
   - Attention + MLP inside one block
   - Tiny NumPy forward pass
4. [04_pretraining_objectives.ipynb](./04_pretraining_objectives.ipynb)
   - Causal LM vs Masked LM
   - Cross-entropy and perplexity
   - Toy objective calculations

## Papers

- [Attention Is All You Need (Vaswani et al., 2017)](./Papers/1706.03762v7.pdf)

## Who this is for

- Beginners who want intuition before heavy math
- Practitioners who want to refresh fundamentals
- Anyone who wants a clear path from concepts to implementation

## Publish Notebook to Jekyll

Keep authoring in notebooks, then publish to your Jekyll blog as a styled post.

Script:
- `scripts/publish_notebook_to_jekyll.sh`

Example:

```bash
./scripts/publish_notebook_to_jekyll.sh 01_foundations_attention_embeddings.ipynb \
  --site ~/GitHub/your-jekyll-site \
  --title "Lesson 01: Foundations - Attention and Embeddings" \
  --categories "llm,fundamentals,transformers" \
  --tags "attention,embeddings"
```

What it does:
- Runs `nbconvert` to Markdown
- Creates a Jekyll post in `your-site/_posts/YYYY-MM-DD-slug.md`
- Copies notebook images to `your-site/assets/notebooks/<slug>/`
- Rewrites image paths in Markdown for Jekyll
- Copies the source `.ipynb` and appends a download link
