%lang starknet
%builtins pedersen range_check
from starkware.cairo.common.math import assert_nn, assert_le
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from openzeppelin.token.erc721.library import (
    ERC721_name,
    ERC721_symbol,
    ERC721_balanceOf,
    ERC721_ownerOf,
    ERC721_getApproved,
    ERC721_isApprovedForAll,
    ERC721_tokenURI,
    ERC721_approve,
    ERC721_setApprovalForAll,
    ERC721_transferFrom,
    ERC721_safeTransferFrom,
    ERC721_safeMint,
    ERC721_initializer,
    ERC721_setTokenURI,
)
from openzeppelin.introspection.ERC165 import ERC165

# https://etherscan.deth.net/address/0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270#code

struct Project:
    member name : felt
    member artist : felt
    member maxInvocations : felt
    member paused : felt
end

const ONE_MILLION = 1000000

@event
func Mint(address : felt, tokenId : felt, projectId : felt):
end

@storage_var
func projects(id : felt) -> (project : Project):
end

@storage_var 
func nextProjectId() -> (id : felt):
end

@storage_var
func invocations(projectId : felt) -> (invocations : felt):
end

@storage_var
func tokenIdToHash(tokenId : felt) -> (hash : felt):
end

@storage_var
func projectScript(projectId : felt) -> (script : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    nextProjectId.write(1)
    ERC721_initializer('StarkBlocks', 'STKBKS')
    return ()
end



@view
func supportsInterface{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(interfaceId: felt) -> (success: felt):
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end

@view
func name{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC721_name()
    return (name)
end

@view
func symbol{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC721_symbol()
    return (symbol)
end

@view
func balanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance) = ERC721_balanceOf(owner)
    return (balance)
end

@view
func getApproved{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (approved: felt):
    let (approved) = ERC721_getApproved(token_id)
    return (approved)
end

@view
func isApprovedForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner: felt, operator: felt) -> (isApproved: felt):
    let (isApproved) = ERC721_isApprovedForAll(owner, operator)
    return (isApproved)
end

@external
func approve{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    ERC721_approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(from_: felt, to: felt, tokenId: Uint256):
    ERC721_transferFrom(from_, to, tokenId)
    return ()
end

@external
func safeTransferFrom{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*):
    ERC721_safeTransferFrom(from_, to, tokenId, data_len, data)
    return ()
end

@view
func getNextProjectId{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (id : felt):
    let (id) = nextProjectId.read()
    return (id)
end

@view
func getProjectScript{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(projectId : felt) -> (script : felt):
    let (script) = projectScript.read(projectId)
    return (script)
end

@view
func getInvocations{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(projectId : felt) -> (invocations : felt):
    let (n) = invocations.read(projectId)
    return (n)
end

@view
func getTokenHash{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId : felt) -> (hash : felt):
    let (hash) = tokenIdToHash.read(tokenId)
    return (hash)
end

@external
func addProject{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_project : Project) -> (id : felt):
    # get the caller address
    let (address) = get_caller_address()
    # get the next project id
    let (id) = nextProjectId.read()
    # increment the next project id
    nextProjectId.write(id + 1)
    # add the project to the list
    projects.write(id, _project)
    # return the project id
    return (id)
end

@external
func addProjectScript{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(projectId : felt, script : felt):
    # add the project script to the list
    projectScript.write(projectId, script)
    return ()
end

@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(to : felt, projectId : felt) -> (tokenId : felt):
    let (project) = projects.read(projectId)
    let (_invocations) = invocations.read(projectId)
    let invocation = _invocations + 1

    with_attr error_message(
        "Must not exceed max invocations"):
        assert_le(invocation, project.maxInvocations)
    end

    let (tokenId) = _mintToken(to, projectId)

    return (tokenId)
end

func _mintToken{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(to : felt, projectId : felt) -> (tokenId : felt):
    alloc_locals
    let (project) = projects.read(projectId)
    let (_invocations) = invocations.read(projectId)

    let tokenIdToBe = (projectId * ONE_MILLION) + _invocations

    invocations.write(projectId, _invocations + 1)

    let (hash) = hash2{hash_ptr=pedersen_ptr}(69, 420) # should be a random number
    tokenIdToHash.write(tokenIdToBe, hash)

    let id : Uint256 = Uint256(tokenIdToBe, 0)
    _mint(to, id)
    Mint.emit(to, tokenIdToBe, projectId)
    
    return (tokenIdToBe)
end

func _mint{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    let (data : felt*) = alloc()
    ERC721_safeMint(to, tokenId, 0, data)
    ERC721_setTokenURI(tokenId, 0)
    return ()
end


