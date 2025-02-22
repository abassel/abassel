# Getting Started with the LLM CLI Tool: A Comprehensive Guide

Created: 2025-02-23

## Installation and Setup

First, install the base LLM tool using Homebrew:

```bash
brew install llm
```

To work with Ollama models, install the Ollama plugin:

```bash
llm install llm-ollama
```

## Managing Models

View available models:
```bash
llm models
```

Check your default model:
```bash
llm models default
```

Set a new default model:
```bash
llm models default "llama3.1:8b"
```

Try a specific model without changing default:
```bash
llm -m "deepseek-r1:1.5b" 'Hi'
```

## Basic Usage Examples

### Text Generation
Want to generate creative content? Try this:
```bash
llm 'Ten names for cheesecakes' --option temperature 1.5
```

### Code Review
Review git changes easily:
```bash
git diff | llm --system 'Describe these changes'
```

Want to see all available options?
```bash
llm models --options
```

## Working with Images

The LLM CLI tool supports multiple vision models. Here are some examples:

### Using Llama Vision
```bash
llm -m "llama3.2-vision:11b" "Describe this image" -a https://static.simonwillison.net/static/2024/pelicans.jpg
```

### Using LLaVA
```bash
llm -m "llava:7b" "Describe this image" -a https://static.simonwillison.net/static/2024/pelicans.jpg
```

### Processing Local Images
```bash
cat image.jpg | llm "describe this image" -a -
```

## Log Management

The LLM CLI provides robust logging capabilities:

```bash
# View recent logs
llm logs -n 2 --short

# Clear logs
llm logs -c

# Show log file path
llm logs path

# Check log status
llm logs status

# Extract log content
llm logs --extract

# Search logs
llm logs -q 'cheesecake'
```

## Embedding Support

Generate embeddings for text or images:

```bash
# Text embedding
llm embed -c 'This is some content' -m 3-small

# Image embedding
llm embed --binary -m clip -i image.jpg
```

## Recommended Companion Tools

To enhance your LLM CLI experience, consider these complementary tools:

- [strip-tags](https://github.com/simonw/strip-tags#strip-tags): Clean HTML content
- [symbex](https://github.com/simonw/symbex): Symbolic execution tool

## Further Reading

For more detailed information, check out these resources:
- [Official LLM Documentation](https://llm.datasette.io/en/stable/index.html)
- [LLM-Ollama Integration](https://github.com/taketwo/llm-ollama)
