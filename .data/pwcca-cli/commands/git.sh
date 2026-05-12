# Passthrough to git in the dotfiles repo

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: pwcca git <args...>"
    echo ""
    echo "Run git commands scoped to the dotfiles repository."
    echo ""
    echo "Examples:"
    echo "  pwcca git status"
    echo "  pwcca git log --oneline -5"
    echo "  pwcca git diff"
    return 0
fi

git -C "$DOTS_DIR" "$@"
