use anchor_lang::prelude::*;

declare_id!("6pXW4oA1MqYmpZYnhJAmE1YbuzXDmWdhnBCop3HbKy8U");

#[program]
pub mod hello_anchor {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize {}
