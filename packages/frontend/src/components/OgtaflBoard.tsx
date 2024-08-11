import React from 'react';

const BOARD_SIZE = 11;

const pieces = {
    attacker: '/figures/attacker.png',
    defender: '/figures/defender.png',
    king: '/kings/eth.png'
};

const initialBoard = [
    [null, null, null, 'attacker', 'attacker', 'attacker', 'attacker', 'attacker', null, null, null],
    [null, null, null, null, null, 'attacker', null, null, null, null, null],
    [null, null, null, null, null, null, null, null, null, null, null],
    ['attacker', null, null, null, null, 'defender', null, null, null, null, 'attacker'],
    ['attacker', null, null, null, 'defender', 'defender', 'defender', null, null, null, 'attacker'],
    ['attacker', 'attacker', null, 'defender', 'defender', 'king', 'defender', 'defender', null, 'attacker', 'attacker'],
    ['attacker', null, null, null, 'defender', 'defender', 'defender', null, null, null, 'attacker'],
    ['attacker', null, null, null, null, 'defender', null, null, null, null, 'attacker'],
    [null, null, null, null, null, null, null, null, null, null, null],
    [null, null, null, null, null, 'attacker', null, null, null, null, null],
    [null, null, null, 'attacker', 'attacker', 'attacker', 'attacker', 'attacker', null, null, null],
];

const OgtaflBoard: React.FC = () => {
    const renderSquare = (piece: string | null, index: number) => {
        const imgSrc = piece ? pieces[piece as keyof typeof pieces] : null;
        return (
            <div key={index} style={{ width: '100px', height: '100px', border: '1px solid black' }}>
                {imgSrc && <img src={imgSrc} alt={piece || ''} style={{ width: '100%', height: '100%' }} />}
            </div>
        );
    };

    return (
        <div style={{ display: 'grid', gridTemplateColumns: `repeat(${BOARD_SIZE}, 100px)` }}>
            {initialBoard.flat().map((piece, index) => renderSquare(piece, index))}
        </div>
    );
}

export default OgtaflBoard;
